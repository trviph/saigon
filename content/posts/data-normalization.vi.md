+++
draft = true
title = "Chuẩn Hoá Dữ Liệu"
date = "2025-04-21T17:22:06+07:00"
author = "trviph"
cover = ""
tags = ["database", "data-consistency", "data-redundancy"]
keywords = ["database", "data-consistency", "data-redundancy"]
showFullContent = false
readingTime = true
hideComments = false
toc = true
tocTitle = "Mục lục"
+++

Bốn dạng chuẩn dùng để giúp cho việc model dữ liệu -> giảm redundancy -> tăng consistency.

## Dạng chuẩn thứ nhất

Dữ liệu thoả mãn dạng chuẩn thứ nhất, gọi tắt là 1NF (viết tắt của first normal form), khi dữ liệu không tồn tại một thuộc tính đa trị (đa giá trị) nào. 1NF giúp cho chúng ta lược bỏ dữ liệu trùng lặp (redundant data) và giảm đi độ phức tạp của mô hình dữ liệu. Cùng tìm hiểu qua một số ví dụ về thuộc tính đa trị.

### Nhóm trùng lặp

Thuộc tính nhóm trùng lặp là một thuộc tính đa trị khi giá trị của nó là một mảng bao gồm nhiều phần tử độc lập với nhau.

```text
------------------------------------------------
| user_id | phone_numbers        | signup_date |
------------------------------------------------
|       1 | (+84) 001, (+84) 002 |  2025-04-21 |
|       2 | (+10) 012            |  2025-04-21 |
|       3 | null                 |  2025-04-21 |
|       4 | (+11) 002            |  2025-04-21 |
|       5 |                      |  2025-04-21 |
------------------------------------------------
```

Ở bảng trên ta thấy được người dùng có một thuộc tính mang nhóm trùng lặp đó chính là `phone_numbers`.

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
|       1 | (+84) 002      |
|       2 | (+10) 012      |
|       4 | (+11) 002      |
----------------------------
```

```text
-----------------------------------------------------------
| user_id | phone_number_1 | phone_number_2 | signup_date |
-----------------------------------------------------------
|       1 | (+84) 001      | (+84) 002      |  2025-04-21 |
|       2 | (+10) 012      | null           |  2025-04-21 |
|       3 |                | null           |  2025-04-21 |
|       4 | (+11) 002      | null           |  2025-04-21 |
|       5 | null           |                |  2025-04-21 |
-----------------------------------------------------------
```

Ví dụ bên trên tồn tại hai thuộc tính giống nhau là `phone_number_1` và `phone_number_2` nhưng vì đây là các thuộc tính đơn trị, nên chúng hoàn toàn **không vi phạm** 1NF. Tuy không vi phạm nhưng đây là một anti-pattern trong thiết kế cơ sở dữ liệu.

### Thuộc tính là một bảng

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

```text
------------------------------------------------------
| user_id | name     | chilren                       |
------------------------------------------------------
|       1 | John Doe | {"id": 3, "name": "Doe Doe" } |
|       2 | Jane Doe | {"id": 3, "name": "Doe Doe" } |
|       3 | Doe Doe  | null                          |
------------------------------------------------------
```

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

```text
-------------------------------------------------------------------------------------
| user_id | name     | chilren                                                      |
-------------------------------------------------------------------------------------
|       1 | John Doe | {"id": 3, "name": "Doe Doe", "date_of_birth": "2000-01-01" } |
|       2 | Jane Doe | {"id": 3, "name": "Doe Doe" }                                |
|       3 | Doe Doe  | null                                                         |
-------------------------------------------------------------------------------------
```
