+++
draft = true
title = "Chuẩn Hoá Dữ Liệu"
date = "2025-04-21T17:22:06+07:00"
author = "trviph"
cover = ""
tags = ["database", "data-consistency", "data-redundancy", "data-modeling"]
keywords = ["database", "data-consistency", "data-redundancy", "data-modeling"]
showFullContent = false
readingTime = true
hideComments = false
toc = true
tocTitle = "Mục lục"
+++

## Dạng chuẩn thứ nhất

Dữ liệu thoả mãn dạng chuẩn thứ nhất, gọi tắt là 1NF (first normal form), khi dữ liệu không tồn tại một thuộc tính đa trị (đa giá trị) nào. 1NF giúp cho chúng ta lược bỏ dữ liệu trùng lặp (redundant data) và giảm đi độ phức tạp của mô hình dữ liệu. Một số ví dụ về thuộc tính đa trị, bao gồm:

### Nhóm trùng lặp

Thuộc tính nhóm trùng lặp là một thuộc tính đa trị khi giá trị của nó là một mảng bao gồm nhiều phần tử độc lập với nhau.

```text
------------------------------------------------
| user_id | phone_numbers        | signup_date |
------------------------------------------------
|       1 | (+84) 001, (+10) 002 |  2025-04-21 |
|       2 | (+10) 012            |  2025-04-21 |
|       3 | null                 |  2025-04-21 |
|       4 | (+11) 002            |  2025-04-21 |
|       5 |                      |  2025-04-21 |
------------------------------------------------
```

Ở bảng trên ta thấy được người dùng có một thuộc tính mang nhóm trùng lặp đó chính là `phone_numbers`. Dữ liệu được lưu trữ theo cách này đòi hỏi các logic xử lý chuỗi phức tạp khi thực hiện truy vấn dựa vào thuộc tính. Một câu truy vấn tính toán xem mỗi một `user_id` có bao nhiêu `phone_numbers` độc nhất hay đếm xem có bao nhiêu số điện thoại có mã vùng là `(+84)` là khá phức tạp. Thay vào đó ta có thể chuẩn hoá dữ liệu như ví dụ sau.

```text
-------------------------
| user_id | signup_date |
-------------------------
|       1 |  2025-04-21 |
|       2 |  2025-04-21 |
|       3 |  2025-04-21 |
|       4 |  2025-04-21 |
|       5 |  2025-04-21 |
-------------------------

----------------------------
| user_id | phone_number   |
----------------------------
|       1 | (+84) 001      |
|       1 | (+10) 002      |
|       2 | (+10) 012      |
|       4 | (+11) 002      |
----------------------------
```

Dữ liệu giờ đây được tách thành hai bảng riêng biệt, việc truy vấn trên thuộc tính dựa vào `phone_number` cũng dễ dàng hơn. Một lưu ý nhỏ rằng nhóm trùng lặp thường bị nhầm lẫn là nhiều cột đơn trị mang ý nghĩa giống nhau, tương tự dưới đây:

```text
-----------------------------------------------------------
| user_id | phone_number_1 | phone_number_2 | signup_date |
-----------------------------------------------------------
|       1 | (+84) 001      | (+10) 002      |  2025-04-21 |
|       2 | (+10) 012      | null           |  2025-04-21 |
|       3 |                | null           |  2025-04-21 |
|       4 | (+11) 002      | null           |  2025-04-21 |
|       5 | null           |                |  2025-04-21 |
-----------------------------------------------------------
```

Bảng trên tồn tại hai thuộc tính ý nghĩa giống nhau là `phone_number_1` và `phone_number_2` nhưng vì đây là các thuộc tính đơn trị, chúng không phải là nhóm trùng lặp, nên hoàn toàn **không vi phạm** 1NF. Tuy nhiên đây là một anti-pattern cần tránh trong thiết kế cơ sở dữ liệu.

### Thuộc tính là một bảng

Bảng dưới là một ví dụ cho thuộc tính đa trị dạng bảng, thuộc tính `children` chứa giá trị là một bảng con.

```text
-------------------------------------------------
| user_id | name     | chilren                  |
-------------------------------------------------
|         |          |                          |
|         |          |  ----------------------  |
|         |          |  | user_id | name     |  |
|       1 | John Doe |  ----------------------  |
|         |          |  |       3 | Doe Doe  |  |
|         |          |  ----------------------  |
|         |          |                          |
|---------|----------|--------------------------|
|         |          |                          |
|         |          |  ----------------------  |
|         |          |  | user_id | name     |  |
|       1 | Jane Doe |  ----------------------  |
|         |          |  |       3 | Doe Doe  |  |
|         |          |  ----------------------  |
|         |          |                          |
|---------|----------|--------------------------|
|       3 | Doe Doe  |  null                    |
-------------------------------------------------
```

Nhìn vào ví dụ trên có thể bạn sẽ phì cười, vì ví dụ này là không thể xảy ra do hoàn toàn không có cơ sở dữ liệu quan hệ nào hỗ trợ việc sử dụng một bảng làm giá trị cho một cột. Tuy nhiên gần đây nhiều cơ sở dữ liệu quan hệ đã hỗ trợ kiểu dữ liệu JSON, khiến cho việc sử dụng một bảng cho giá trị cột không còn là điều không thể nữa. Như ví dụ sau đây:

```text
--------------------------------------------------------
| user_id | name     | chilren                         |
--------------------------------------------------------
|       1 | John Doe | [{"id": 3, "name": "Doe Doe" }] |
|       2 | Jane Doe | [{"id": 3, "name": "Doe Doe" }] |
|       3 | Doe Doe  | null                            |
--------------------------------------------------------
```

Tuy cách biễu diễn có khác đi, nhưng về tính chất hai ví dụ bên trên là như nhau. Việc lưu trữ dữ liệu như này sẽ khiến cho dữ liệu bị trùng lặp, dẫn đến khi ta cập nhật dữ liệu cho `Doe Doe` ta phải đồng thời cập nhật lại thông tin của `Doe Doe` cho `John Doe` và `Jane Doe`.

Kỹ thuật này trong các cơ sở dữ liệu NoSQL thường gọi là nhúng dữ liệu (embedding). Nhúng dữ liệu giúp tăng tốc độ đọc dữ liệu do khi đọc ta không cần phải thực hiện select hay join dữ liệu được tham chiếu (referenced). Đổi lại là tốc độ viết sẽ chậm lại, do giờ đây khi thêm mới hay cập nhật ta phải viết nhiều lần vào nhiều record khác nhau. Điều này cũng có nguy cơ dẫn đến bất đồng bộ dữ liệu nếu lúc cập nhật bị sai sót, thiếu, stale cache, ...

Nhúng dữ liệu không hẳn là xấu, nên dựa vào tình huống mà sử dụng cho phù hợp. Tuy nhiên nhúng dữ liệu lại là một vi phạm của 1NF, để thoả mãn 1NF ta cần chuyển đổi từ nhúng dữ liệu sang tham chiếu như sau:

```text
----------------------
| user_id | name     |
----------------------
|       1 | John Doe |
|       2 | Jane Doe |
|       3 | Doe Doe  |
----------------------

----------------------
| user_id | child_id |
----------------------
|       1 |        3 |
|       2 |        3 |
----------------------
```

Như đã trao đổi bên trên, giờ đây việc thay đổi thông tin của `Doe Doe` trở nên dễ dàng hơn rất nhiều. Ta cũng có thể thay đổi thiết kế mịn hơn (mịn hơn != tốt hơn), như sau:

```text
----------------------
| user_id | name     |
----------------------
|       1 | John Doe |
|       2 | Jane Doe |
|       3 | Doe Doe  |
----------------------

---------------------------------------
| user_id | relation  | other_user_id |
---------------------------------------
|       1 | parent_of |             3 |
|       2 | parent_of |             3 |
|       3 |  child_of |             1 |
|       3 |  child_of |             2 |
---------------------------------------
```

### Dữ liệu không đồng nhất số lượng thuộc tính

Một thuộc tính nữa mà 1NF yêu cầu đó chính là số lượng thuộc tính giữa tất cả các record là như nhau. Các hệ cơ sở dữ liệu quan hệ gần như không cho phép điều này, do tất cả dữ liệu đều cần thoả mãn theo một schema được định nghĩa sẵn. Tuy nhiên cũng như vấn đề ở bên trên, với sự xuất hiện của JSON, giờ đây việc này không còn là không thể.

```text
--------------------------------------------------------
| user_id | name     | misc_info                       |
--------------------------------------------------------
|       1 | John Doe | {"date_of_birth": "2000-01-01"} |
|       2 | Jane Doe | {"hobbies": ["read", "write"]}  |
|       3 | Doe Doe  | {"hobbies": ["running"]}        |
--------------------------------------------------------
```

Liệu bảng trên có vi phạm 1NF? Còn tuỳ. Nếu toàn bộ giá trị của cột `misc_info` được xem là một thuộc tính duy nhất của record thì nó không vi phạm 1NF. Nhưng nếu tường khoá JSON trong cột `misc_info` được xem là một thuộc tính độc lập của record, và được dùng cho việc truy vấn thì đây là một vi phạm của 1NF.

### Sử dụng JSON là vi phạm 1NF?

Như nói trên, sử dụng JSON không đồng nghĩa với vi phạm 1NF. Việc vi phạm 1NF hay không còn tuỳ vào cách chúng ta sử dụng JSON như thế nào. Nói dễ hiểu, nếu chúng ta đối xử dữ liệu JSON như một kiểu dữ liệu chuỗi bình thường thì không là vấn đề gì. Tuy nhiên nếu chúng ta bắt đầu thực hiện filter, aggregate dựa vào các thuộc tính trong cột JSON, có lẽ đã đến lúc suy nghĩ lại thiết kế dữ liệu.
