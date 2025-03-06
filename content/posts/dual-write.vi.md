+++
title = "Dual Write"
date = "2025-03-05T19:27:42+07:00"
author = "trviph"
tags = ["backend", "data-consistency"]
keywords = ["backend", "data-consistency"]
cover = "/img/dual-write/intro-light.vi.svg"
showFullContent = false
readingTime = true
color = "paper"
+++

Khi làm việc với các hệ thống backend, thường có một pattern hay được sử dụng để xử lý dữ liệu nhận được.
Chúng ta thường sẽ có một máy chủ chờ để nhận dữ liệu từ một message broker hoặc là qua một API nào đó.
Khi dữ liệu này được truyền tới máy chủ, ta thường sẽ phải xử lý chuẩn hoá dữ liệu này theo logic nghiệp
vụ. Dữ liệu này sẽ được lưu trữ vào database sau khi đã được xử lý. Và bước cuối cùng của quá trình này
thường sẽ là máy chủ tiếp tục gửi dữ liệu đã được xử lý này đến các hệ thống, máy chủ tiếp theo để thực
hiện xử lý tiếp nghiệp vụ. Quá trình này được gọi là dual write, hay còn được gọi là multi-write hoặc
sync-write.

# Vấn Đề

Pattern này nhìn chung có vẻ dễ hiểu, dễ cài đặt, vậy cái vấn đề mà nó mang lại là gì?
Vấn đề chính của pattern này là nó dễ bị lỗi, mà khi đã lỗi rồi thì sẽ thường dẫn đến các lỗi
về dữ liệu bị bất đồng bộ (không khớp nhau) giữa các hệ thống hay dịch vụ. Lỗi bất đồng bộ dữ liệu
lại cực kỳ khó debug, đòi hỏi phải vò đầu bứt tai đến mức sói trán.

{{< image src="/img/dual-write/failure-light.vi.svg" alt="" position="center" >}}

Lỗi này xảy ra khi chúng ta đã lưu trữ hoặc cập nhật dữ liệu một cách thành công vào database sau khi
đã xử lý qua dữ liệu theo nghiệp vụ, nhưng lại thất bại trong việc thông báo cho các máy chủ tiếp theo
rằng dữ liệu mới đã được thêm hoặc dữ liệu cũ đã được thay đổi. Khiến cho các hệ thống downstream chứa
dữ liệu cũ không được cập nhật hoặc không có dữ liệu mới dẫn đến dữ liệu bị mất đồng bộ giữa các hệ thống
với nhau.

There are multiple possible reasons for this failure to occur. Maybe there was a network partition
happening at the time, causing the receiver of data to be unreachable, or the receiver simply having
downtime due to errors or maintenance, or it was something as simple as human errors sending
a wrong schema to a wrong API, etc. But whatever the cause, the data is now mismatched and we must
somehow fix it.

Có một vài nguyên do lý giải cho việc này xảy ra. Có thể trong lúc truyền tải dữ liệu đường truyền mạng
có vấn đề, dẫn đến mất kết nối, hoặc có thể do máy chủ sau bị lỗi hay đang bảo trì nên không thể kết nối
được, hoặc chỉ đơn giản do lỗi con người, truyền sai schema dữ liệu, gọi sai API, ... Cho dù lý do có là
gì đi nữa, thì nghĩa vụ của chúng ta vẫn phải là khắc phục được nó.

## Ví Dụ Về Dual Write Trong E-commerce

Trong các hệ thống e-commerce, để có thể dễ dàng scale out hệ thống và các team kỹ sư, kiến trúc của các hệ
thống này thường sẽ được chia ra thành nhiều hệ thống, service nhỏ với các boundary được định nghĩa rõ ràng.
Một số service thường thấy các hệ thống e-commerce có thể bao gồm: một payment gateway với mục đích lưu trữ
thông tin thanh toán của khách hàng cũng như thực hiện thanh toán cho các giao dịch, đơn hàng; một hệ thống
quản lý đơn hàng, thường viết tắt là OMS dựa vào cụm từ Order Management System, với nhiệm vụ quản lý và
theo dõi đơn hàng; một hệ thống quản kho để cho người bán có thể quản lý sản phẩm của mình về giá cả,
tồn kho, lưu trữ, ...; một hệ thống tìm kiếm giúp người mua có thể tìm được sản phẩm dựa trên các query,
bộ lọc, sở thích, lịch sử mua bán, ...

{{< image src="/img/dual-write/ecommerce-checkout-light.vi.svg" alt="" position="center" >}}

Trong quá trình thanh toán, sau khi người mua đã thanh toán cho một đơn hàng thành công, payment gateway
thường có nhiệm vụ phải báo cho OMS biết rằng đơn hàng đã được thanh toán thành công, để có thể chuyển
sang các trạng thái khác như đóng gói, trung chuyển, ... Tuy nhiên, nếu việc payment gateway thông báo
cho OMS bị thất bại sẽ dẫn đến việc người dùng đã trả tiền nhưng đơn hàng lại bị hoãn lại, khách
hàng chờ lâu để nhận hỗ trợ, sẽ khiến trải nghiệm mua hàng trở nên tồi tệ.

{{< image src="/img/dual-write/ecommerce-listing-creation-light.vi.svg" alt="" position="center" >}}

Hay trong quá trình tạo sản phẩm, sau khi người bán tạo sản phẩm mới, hệ thống quản lý kho phải có nhiệm vụ
thông báo cho hệ thống tìm kiếm về sản phẩm mới. Khi được thông báo, hệ thống tìm kiếm thường sẽ tạo dữ liệu
mới về các thông tin sản phẩm và thực hiện index, caching để tối ưu hoá trải nghiệm tìm kiếm. Vì vậy, nếu
hệ thống quản lý kho thất bại trong việc thông báo sản phẩm mới cho hệ thống tìm kiếm, sẽ khiến cho sản phẩm
này không tồn tại trên sàn, người mua không thể tìm kiếm ra được. Khiến người bán bị mất đi khách hàng ảnh hưởng đến
doanh thu của họ, có thể dẫn đến thiệt hại về uy tín cho sàn e-commerce trong cộng đồng người bán.

# Một Số Giải Pháp Không Hiệu Quả

Giờ chúng ta biết được dual write là gì và các vấn đề mà nó mang lại. Hãy cùng nhau tìm hiểu một số cách
sẽ *không* thể khắc phục được các vấn đề này.

## Khôi Phục Lại Dữ Liệu

Liệu chúng ta có thể khôi phục lại dữ liệu trong trường hợp thất bại được không? Được, tuy nhiên việc
khôi phục dữ liệu cũng có thể bị thất bại nên chúng ta phải làm gì tiếp nếu nó cũng thất bại?
Chưa kể đến việc chúng ta sẽ cần phải lưu trữ thêm trạng thái dữ liệu trước đó để có thể khôi phục được.

Thế còn nếu chúng ta không commit dữ liệu vào database trừ khi các service downstream được thông báo thành công,
nếu làm theo cách nào thì ta không cần phải lưu trữ trạng thái trước đó của dữ liệu? Việc thực hiện commit hay
ghi vào database cũng có thể thất bại.

Theo ý kiến cá nhân tôi, thì các này sẽ trở nên phức tạp rất nhanh mà không mang lại hiệu quả nào.

## Lưu Dữ Liệu Sau Khi Gửi

Nếu chúng ta ghi dữ liệu vào database chỉ sau khi đã thông báo thành công cho các service downstream thì sao?
Hướng tiếp cận này cũng tương tự như hướng tiếp cận chỉ commit database sau khi thông báo đã trao đổi ở trên,
việc viết vào database không được đảm bảo sẽ thành công, nên chỉ thay đổi trình tự ghi dữ liệu sẽ không giải
quyết được vấn đề.

## Thử Lại

Nếu có lỗi xảy ra, thường chỉ cần thử lại sẽ là một cách giải quyết đủ tốt.
Tuy nhiên, ta cần phải chú trọng đến các vấn đề như thử lại bao nhiều lần, khoảng chờ giữa các lần
thử là bao lâu?

Nếu như service downstream không thể kết nối được trong một khoảng thời gian dài, ví dụ trong năm phút,
các thuật toán thử lại thường sẽ đã bắt đầu bỏ cuộc trong khoảng thời gian này.

Sử dụng exponential backoff để thử lại thì sao? Hướng này có thể khả thi, tuy nhiên nếu hệ thống *của chúng
ta* bị lỗi và crash trong khoảng thời gian này, thì sau khi hệ thống phục hồi lại ta sẽ mất đi context của
việc hệ thống đang làm trước đó. Ta cần phải ghi nhớ được context, state của hệ thống bằng một cách nào đó.

# Một Số Giải Pháp Hiệu Quả

Một số pattern để xử lý dual write một cách hiệu quả là:

- Transactional Outbox Pattern
- Listen to Yourself Pattern
- Change Data Capture Pattern

Trong phần này, chúng ta đã điểm mặt gọi tên một số pattern dùng để xử lý dual write một cách hiệu quả
mà không đi vào bất kỳ một chi tiết nào, vì bài viết này theo tôi cũng đã khá dài ~và tôi khá lười~.
Trong tương lai tôi có thể sẽ viết về các pattern này, nhưng hiện tại nếu bạn muốn tìm hiểu thêm thì phải
tự lăn vào bếp thôi :))

# Đọc Thêm

- https://www.confluent.io/blog/dual-write-problem/
- https://newsletter.systemdesignclassroom.com/p/i-have-seen-this-mistake-in-production
- https://microservices.io/patterns/data/transactional-outbox.html
- https://debezium.io/blog/2020/02/10/event-sourcing-vs-cdc/
- https://developers.redhat.com/articles/2021/09/21/distributed-transaction-patterns-microservices-compared
