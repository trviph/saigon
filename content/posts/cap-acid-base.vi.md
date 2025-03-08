+++
draft = true
title = "CAP vs ACID vs BASE?!"
date = "2025-03-07T15:04:27+07:00"
author = "trviph"
tags = ["database"]
keywords = ["database"]
cover = "/img/cap-acid-base/cover-light.svg"
coverCaption = ""
showFullContent = false
readingTime = true
color = "paper"
toc = true
tocTitle = "Mục lục"
+++

Khi tìm hiểu về database, chúng ta thường nghe đến các khái niệm như định lý CAP, tính chất ACID, tính chất BASE.
Các khái niệm này là gì mà đi đâu ta cũng gặp phải? Hãy cùng tôi tìm hiểu trong bài này!

## CAP nghĩa là cái nón?

`CAP` là từ viết tắt của `Consitency, Availability, Partition-tolerance` được giới thiệu bởi Eric Brewer vào
năm 2000 trong một buổi diễn thuyết. Brewer cho rằng, trong một hệ thống phân tán (distributed system) khi
một sự kiện chia cách (network partition) xảy ra, hệ thống chỉ có thể lựa chọn giữa `consistency` hoặc `availability`. Vậy ba tính chất này là gì mà các hệ thống phân tán lại muốn có, và tại sao chúng không thể cùng lúc thoả mãn cả ba?

### C có nghĩa là consistency

Trong ngành khoa học máy tính, đặc biệt trong ngữ cảnh về dữ liệu, từ `consistency` có thể nói bị quá tải
về nghĩa. Khi nó được sử dụng trong quá nhiều định nghĩa (consistency đều có mặt trong CAP, ACID, BASE)
nên thường dẫn đến nhầm lẫn. Trong định lý CAP, một hệ thống thoả được tính chất consistency khi tất cả
mọi máy khách của hệ thống đều có cùng một phiên bản dữ liệu tại bất kỳ điểm thời gian nào.
Nói cách khác, sau một hành động viết hoặc cập nhật dữ liệu vào hệ thống thì các hành động đọc tiếp theo đó
đều phải cùng thấy được phiên bản dữ liệu mới nhất. `Consistency` theo định lý CAP còn thường được gọi
là `strong consistency` khác với `eventual consistency` trong tính chất BASE.

`Consistency` là một tính chất được nhiều người theo đuổi, do đây là một tính cất cần thiết trong các hệ thống
mang tính chất giao dịch. Tưởng tượng trong hệ thống ngân hàng, bạn vừa gửi 1.000.000.000 tỷ VNĐ tại ngân
hàng (whao!) nhưng khi tra cứu tài khoản lại không thấy khoản tiền đó! Một thảm hoạ!

{{< image src="/img/cap-acid-base/cap-inconsistent-light.vi.svg" alt="" position="center" >}}

### A có nghĩa là availability

Theo như Seth Gilbert và Nancy Lynch, một hệ thống phân tán thoả được tính chất `availability` khi tất cả
mọi yêu cầu đến một node đang hoạt động trong hệ thống đều phải được nhận lại được phản hồi hợp lệ.
Nói cách khác hệ thống phải có uptime là 100%, miễn là kết nối mạng vẫn còn hoạt động được thì
người dùng phải sử dụng được hệ thống.

Định nghĩa trên về `availability` là không thực tiễn, do các hệ thống hiện nay đều có downtime
ví dụ như đa phần sản phẩm của Google Cloud có SLA về uptime là 99,99% (mỗi năm sẽ có khoảng 52 phút
9,8 giây downtime) sẽ không thoả mãn được yêu cầu này. Nhưng tôi cảm thấy nó dễ hiểu hơn so với định
nghĩa ban đầu của Brewer rằng: "data is considered highly available if a given consumer of the data
can always reach some replica", tạm dịch: "Dữ liệu có tính sẵn sàng cao khi bất cứ một yêu cầu nào về dữ liệu
phải luôn luôn có được một bản sao nhất định của dữ liệu đó".

`Availability` là một tính chất được nhiều người chú trọng, mọi hệ thống đều được kỳ vọng phải luôn sẵn
sàng tại mọi thời điểm. Nếu hệ thống không hoạt động có thể dẫn đến nhiều hệ luỵ nghiêm trọng, trong e-commerce
chúng ta có thể mất khách hàng, hay trong hệ thống bệnh viện có thể dẫn đến trì hoãn hoạt động của bệnh viện.

### P có nghĩa là partition-tolerance

Một hệ thống gọi là `partition-tolerance` trong trường hợp nếu một phần của hệ thống đó
bị chia cách (partition) do crash, mất kết nối mạng, ... thì các phần còn lại của hệ thống đó
vẫn phải hoạt động như thường.

### Tại sao không thể thoả mãn đồng thời CAP?

Trong một hệ thống có hai node A và B, nếu trong trường hợp có hiện tượng phân cách (partition) xảy ra.
Node A sẽ không thể giao tiếp được với node B, nhưng vì hệ thống này thoả điều kiện `partition-tolerance`
nên vẫn tiếp tục hoạt động, người dùng vẫn có thể tương tác với hệ thống điều này thoả `availability`.
Tuy nhiên, khi dữ liệu được ghi vào A thì sẽ không tồn tại ở B, do hai node này không thể giao tiếp được
với nhau, điều này không thoả được `consistency`. Như vậy hệ thống này chỉ thoả được AP.

Trong một hệ thống khác tương tự như trên, vì muốn dữ liệu phải consistent giữa cả hai node. Nên khi node A phát hiện
kết nối đến node B đã mất, nó sẽ cố kết nối lại khiến cho người dùng không thể tương tác được đến hệ thống làm mất đi
tính `availability`. Tuy nhiên điều này cũng đảm bảo được rằng tại bất kỳ điểm thời gian nào, dữ liệu ở cả hai node là
giống nhau. Như vậy hệ thống này chỉ thoả được CP.

## ACID là chất có tính ăn mòn?

ACID là một đặc trưng thường thấy trong các cơ sở dữ liệu quan hệ, được viết tắt từ
`Atomicity, Consistency, Isolation, Durability`. Gần như bất cứ cơ sở dữ liệu nào cũng phải
có được những đặc trưng này, và chúng cũng thường được dùng làm thước đo độ tin cậy của một
cơ sở dữ liệu bất kỳ.

### A có nghĩa là Atomicity

`Atomicity` là đặc trưng của database về toán tử nhỏ nhất mà các database cần phải thực hiện không phải là một query
(truy vấn) mà là một transaction (giao dịch). Một transaction là một tập hợp của một hoặc nhiều query. Một transaction
chỉ thành công khi tất cả các query trong nó thành công.

Điều này là rất quan trọng, vì trong thực tế, các giao dịch nghiệp vụ thường bao gồm một chuỗi các hành động.
Vi dụ như giao dịch chuyển khoản ngân hàng, thì ngân hàng của bạn cần phải trừ tiền từ tài khoản của bạn và cộng tiền
vào tài khoản mà bạn chuyển đến, và bất kỳ hành động nào bị thất bại thì toàn bộ giao dịch sẽ thất bại. Với `atomicity`,
chúng ta có thể dễ dàng quản lý một transaction mà không cần quan tâm đến các state của dữ liệu trong từng query.

### C có nghĩa là Consistency

`Consistency` trong ACID là một khái niệm khác so với `consistency` trong CAP hay BASE, nó mang ý nghĩa tất cả dữ liệu
trong database sẽ luôn luôn tuân thủ theo các constraint/schema được định nghĩa. Các constraint này bao gồm số trường
của dữ liệu, loại dữ liệu của từng trường, các khoá chính, khoá ngoại, khoá đặc biệt khác, trigger, ...

### I có nghĩa là Isolation

`Isolation` là một đặc tính dùng để cô lập các transaction chạy song song với nhau.

### D có nghĩa là Durability

## Đọc thêm

- Seth Gilbert and Nancy Lynch, "Brewer’s Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services", [comp.nus.edu.sg](https://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf)
- ScylaDB, "CAP Theorem", [scylladb.com](https://www.scylladb.com/glossary/cap-theorem/)
- Martin Kleppmann, "A Critique of the CAP Theorem", [arXiv:1509.05393](https://arxiv.org/abs/1509.05393)
- MySQL, "InnoDB and the ACID Model", [dev.mysql.com](https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html)
- PostgreSQL, "Concurrency Control", [postgresql.org](https://www.postgresql.org/docs/current/mvcc.html)
- MongoDB, "A Guide to ACID Properties in Database Management Systems", [mongodb.com](https://www.mongodb.com/resources/basics/databases/acid-transactions)
- MongoDB, "Multi-Document ACID Transactions on MongoDB", [mongodb.com](https://www.mongodb.com/resources/products/capabilities/mongodb-multi-document-acid-transactions)
- AWS, "Điểm khác biệt giữa ACID và cơ sở dữ liệu BASE là gì?", [aws.amazon.com](https://aws.amazon.com/compare/the-difference-between-acid-and-base-database/)
