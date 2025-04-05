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
+++

Have you ever studied or worked with databases and come across abbreviations such as ACID, BASE, CAP and wondered what these words mean? I have and this post is the result of my research on this topic.

## CAP is a type of headwear?

`CAP` stands for `Consistency, Availability, Partition-tolerance` first introduced by Eric Brewer in a talk in the year 2000. Brewer said that in a distributed system, in the event of a partition (of the network, or communication between nodes in the system), the said system can only choose between `consistency` or `availability` not both. What are these properties, and why can we not choose both?

### C stands for consistency

In computer science, especially in the context of data, the word `consistency` is heavily overloaded. In all of the mentioned words ACID, CAP, BASE involve the word `consistency`. This often leads to misunderstanding of the meaning of the word. In CAP, a system is considered strongly consistent when at every point in time all the nodes in the system must hold a same, single version of data. This means that if you successfully write new data into one node, this newly written data must also exist on all other nodes. This differs from the eventual consistency mentioned in BASE, which allows for nodes in the system to have different versions of data, but will eventually converge at a single version.

Consistency is one of the highly desirable properties of many systems. Imagine in banking, you go to the bank and deposit 1,000,000 USD (whoa!) but when checking your account, due to latency or temporary partition, the deposit is nowhere to be seen! What a disaster!

{{< image src="/img/cap-acid-base/cap-inconsistent-light.en.svg" alt="" position="center" >}}

### A stands for availability

According to Seth Gilbert and Nacy Lynch, a distributed system is considered `highly available` only when every request to a non-failing node must have a valid response. In layman's terms, the system must have an uptime of 100% to be considered highly available.

However, the above definition is not realistic in real life. Many systems like products of Google Cloud have an SLA of 99.99% uptime (convert to around 52 minutes of downtime every year) while not satisfying the above definition but are still considered highly available. But I found it is easier to understand than the following definition provided by Brewer: "Data is considered highly available if a given consumer of the data can always reach some replica".

Availability is also a highly desirable trait of a distributed system, every modern system is expected to be always ready at any time. It can be problematic if the system becomes unavailable, in e-commerce, we will lose customers, and orders to competitors, in healthcare it can cause chaos and delays in treating patients.

### P stands for partition-tolerance

A system is considered to be `partition-tolerance` when in case of a partition event (due to network slowdown, some nodes crashing, ...) the system must continue to operate as normal as if the partition has not occurred.

### Why can we not choose all three?

In a system that has two nodes A and B, if in the event of partition. The A Node won't be able to communicate with the B Node, but because this system is `partition-tolerance`, it will continue to operate. The users can still interact with the systems as normal, this satisfies `availability`. However, because the two nodes now operate in isolation (they can't communicate with each other), data written into A will not immediately exist in B and vice versa, this causes the system to be `inconsistent`. This system is an AP system.

In another system with the same setup, when the two nodes found out that they could not communicate with each other, they stopped receiving all requests coming from the client and tried to reconnect with the other node. This ensures that the system always to be in a `consistent` state, but because the system can not be interacted with it is not considered to be `available`. This system is a CP system.

## ACID is a corrosive substance?

ACID is a property often seen in relational databases, derived from `Atomicity, Consistency, Isolation, Durability`. Nearly every database is expected to have some form or another of this property, it is often used to indicate how reliable a database can be.

### A stands for Atomicity

`Atomicity` is a property that states the smallest unit of work of a database is a transaction, not a query. A transaction can be composed of one or multiple queries. For a transaction to be considered successful, all of the queries in the transaction must also be successful.

This is an important property. Because, in reality, business transactions rarely ever consist of a single query, but are often composed of multiple. Take banking, for example, a transfer transaction often means a deduction of cash from the transferer account and an addition of cash to the receiver account, if any of these steps fail then the whole transfer is considered as failed. With `atomicity`, we are allowed to manage a transaction state without caring about manually handling the query states.

### C stands for Consistency

`Consistency` in ACID is very different from `strong consistency` or `eventual consistency` in CAP or BASE. In ACID, consistency is a property of which the database always guarantees that every data in the database will be consistent with the predefined schema and constraints. These constraints include data type, primary key, unique key, foreign key, trigger, procedure, the number of columns, etc.

### I có nghĩa là Isolation

`Isolation` là một đặc tính dùng để cô lập các transaction chạy song song với nhau, mục tiêu chính của `isolation` là
tránh data race xảy ra, khi có nhiều transaction cùng một lúc truy cập vào cùng một vùng dữ liệu (page, table, record).
Isolation thường được thực hiện bằng cách khoá (bảng, record, index) cho các câu truy vấn dạng Data Manipulation
Language (DML như INSERT, UPDATE, DELETE); khoá (bảng, record, index) hoặc tạo snapshot cho các câu truy vấn dạng Data
Query Language (DQL như SELECT). Có bốn cấp độ isolation, lựa chọn cấp độ isolation cao sẽ giúp tránh được data race
tuy nhiên đổi lại sẽ giảm hiệu năng của database:

#### Read-committed

{{< image src="/img/cap-acid-base/acid-read-committed-light.en.svg" alt="" position="center" >}}

Read-committed là mức isolation thứ hai, tuy nhiên được đề cập đầu tiên do theo tôi để hiểu các cấp độ khác cần phải
hiểu về read-committed. Trong read-committed, các thay đổi trong một transaction sẽ không thấy được bởi các transaction
khác, cho đến khi transaction được commit thành công.

```sql
-- Bắt đầu một transaction
BEGIN;

-- Thêm một record mới vào bảng 'example' của database 'acid'
INSERT INTO 'acid'.'example'('id', 'name')
VALUES 
    -- Các transaction khác sẽ không thấy được record này trong bảng example của database acid
    -- do transaction hiện tại chưa được commit thành công
    (2, "Chuồn chuồn bay cao thì nắng, bay vừa thì râm");

-- Commit transaction, nếu thành công các transaction khác sẽ thấy record ở trên được thêm bào bảng
COMMIT;
```

#### Repeatable-read

{{< image src="/img/cap-acid-base/acid-repeatable-read-light.en.svg" alt="" position="center" >}}

Repeatable-read là mức isolation thứ ba, không chỉ đảm bảo các đặc điểm của read-commited mà còn đảm bảo thêm rằng
trong toàn bộ thời gian mà transaction tồn tại, các trường dữ liệu liên quan sẽ không bị thay đổi.

```sql
-- Bắt đầu một transaction
BEGIN;

-- Record này sẽ bị khoá, đảm bảo không bị transaction khác thay đổi
-- cho đến khi transaction hiện tại được commit
SELECT 'name' FROM 'acid'.'example' WHERE 'id' = 1;

-- Các câu query khác
-- ...

-- Giá trị vẫn sẽ giữ nguyên không thay đổi
SELECT 'name' FROM 'acid'.'example' WHERE 'id' = 1;

-- Commit transaction, và thả các khoá
COMMIT;
```

#### Serializable

{{< image src="/img/cap-acid-base/acid-serializable-light.en.svg" alt="" position="center" >}}

Serializable là cấp độ isolation cao nhất, đảm bảo tất cả những đảm bảo của repeatable-read, thêm vào đó còn đảm bảo
thêm rằng sẽ không record mới xuất hiện cho đến khi transaction hiện tại kết thúc.

```sql
-- Bắt đầu một transaction
BEGIN;

-- Lần query đầu tiên.
SELECT 'name' FROM 'acid'.'example' WHERE 'id' < 9999;

-- Các câu query khác
-- ...

-- Giá trị các record vẫn sẽ giữ nguyên không thay đổi
-- và số lượng record không đổi
SELECT 'name' FROM 'acid'.'example' WHERE 'id' < 9999;

-- Commit transaction, và thả các khoá
COMMIT;
```

#### Dirty-read

Dirty-read là mức isolation thấp nhất, ở dirty read thì hoàn toàn không tồn tại sự cô lập giữa các transaction.

### D có nghĩa là Durability

{{< image src="/img/cap-acid-base/acid-durable-light.en.svg" alt="" position="center" >}}

`Durability` là một đặc trưng tạo nên độ tin cậy của cơ sở dữ liệu, đặc trưng này đảm bảo rằng khi một transaction
đã được commit thành công thì dữ liệu sẽ tồn tại vĩnh viễn, tất nhiên miễn là ổ cứng lưu trữ không bị hư hỏng. Điều
này thường được thực hiện bằng kỹ thuật two-phase commit, backup, hay replicate. Như trong MySQL, với mỗi commit,
database sẽ ghi dữ liệu vào binlog trước khi ghi dữ liệu vào page lưu trữ, nếu MySQL crash trong lúc viết vào page thì có thể đọc từ binlog để khôi phục lại dữ liệu. Ngoài ra binlog còn được dùng để sync dữ liệu giữa các replica.
Tương tự trong MongoDB thì có oplog.

## BASE!?

BASE là một thuật ngữ thường được các cơ sở dữ liệu phân tán sử dụng. Các database được thiết
kế theo BASE, tập trung vào tính `availability` của hệ thống bằng cách hy sinh tính `strong consistency`.
Cả hai khái niệm về `availability` và `strong consistency` là các định nghĩa được sử dụng trong `CAP` đề cập bên trên.

### BA có nghĩa là Basically Available

Đảm bảo rằng hệ thống sẽ luôn luôn sẵn sàng, và tất cả mọi yêu đến hệ thống đều sẽ nhận được một phản hồi hợp lệ.

### S có nghĩa là Soft-State

Soft-State là đặc tính của database cho rằng state (trạng thái, dữ liệu) của database có thể thay đổi ngay cả khi không
có input từ user. Đây được xem là một kết quả của tính `eventual consistency`, khi người dùng viết dữ liệu vào database,
trạng thái của database sẽ không thay đổi ngay lập tức mà sẽ cần một khoảng thời gian để thay đổi có thể được truyền tải
đến tất cả các node.

### E có nghĩa là Eventual Consistency

Eventual consistency đảm bảo sau một khoảng thời gian thì tất cả các node trong hệ thống đều sẽ được đồng bộ với nhau.
Kết quả mang lại là trong tại cùng một thời điểm các node trong hệ thống có thể chứa các phiên bản dữ liệu khác nhau.
Điều này khác với `strong consistency` đảm bảo tất cả các node trong hệ thống sẽ luôn luôn được đồng bộ ngay lập
tức, tất cả các node có cùng một phiên bản dữ liệu.

## Read More

- Seth Gilbert and Nancy Lynch, "Brewer’s Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services", [comp.nus.edu.sg](https://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf)
- ScylaDB, "CAP Theorem", [scylladb.com](https://www.scylladb.com/glossary/cap-theorem/)
- Martin Kleppmann, "A Critique of the CAP Theorem", [arXiv:1509.05393](https://arxiv.org/abs/1509.05393)
- MySQL, "InnoDB and the ACID Model", [dev.mysql.com](https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html)
- PostgreSQL, "Concurrency Control", [postgresql.org](https://www.postgresql.org/docs/current/mvcc.html)
- MongoDB, "A Guide to ACID Properties in Database Management Systems", [mongodb.com](https://www.mongodb.com/resources/basics/databases/acid-transactions)
- MongoDB, "Multi-Document ACID Transactions on MongoDB", [mongodb.com](https://www.mongodb.com/resources/products/capabilities/mongodb-multi-document-acid-transactions)
- AWS, "What’s the Difference Between an ACID and a BASE Database?", [aws.amazon.com](https://aws.amazon.com/compare/the-difference-between-acid-and-base-database/)
