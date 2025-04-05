+++
draft = true
title = "CAP vs ACID vs BASE?!"
date = "2025-03-07T15:04:27+07:00"
lastmod = "2025-04-05T20:28:00+07:00"
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

A system is considered to be `partition-tolerance` when in case of a partition event (due to network slowdown, some nodes crashing, etc.) the system must continue to operate as normal as if the partition has not occurred.

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

### I stands for Isolation

`Isolation` is how the database isolates transactions from each other. This is a form of concurrency control. The purpose is to prevent data races from happening when there are multiple transactions running at the same time trying to modify the same data region (page, table, record, index, etc.). Isolation is usually done by locking data accessed by DML queries (such as INSERT, UPDATE, DELETE) or by creating a snapshot of data for DQL queries (such as SELECT). There are four main isolation levels, the higher the level the less likely for data races to happen but it comes with the cost of performance.

#### Read-committed

{{< image src="/img/cap-acid-base/acid-read-committed-light.en.svg" alt="" position="center" >}}

Read-committed is the second isolation level, but I feel that it is important to understand this first to understand the other isolation levels. In read-committed, every change in the current transaction will not be seen by other transactions until the current transaction is committed successfully. This ensures that you will always see committed data.

```sql
-- Start a transaction
BEGIN;

-- Insert a new record into 'example' table of 'acid' database
INSERT INTO 'acid'.'example'('id', 'name')
VALUES 
    -- Other transactions can't see this record until this transaction is committed successfully
    (2, "Chuồn chuồn bay cao thì nắng, bay vừa thì râm");

-- Commit transaction
COMMIT;
```

#### Repeatable-read

{{< image src="/img/cap-acid-base/acid-repeatable-read-light.en.svg" alt="" position="center" >}}

Repeatable read is the third isolation level, it guarantees read-committed and also guarantees that during the lifetime of the current transaction all the related records, which are used or seen by the current transaction will not be modified by other transactions.

```sql
-- Start a transaction
BEGIN;

-- This record is locked, other transactions can't modified it until this transaction is committed.
SELECT 'name' FROM 'acid'.'example' WHERE 'id' = 1;

-- Other queries
-- etc.

-- The result record is unchanged
SELECT 'name' FROM 'acid'.'example' WHERE 'id' = 1;

-- Commit the transaction
COMMIT;
```

#### Serializable

{{< image src="/img/cap-acid-base/acid-serializable-light.en.svg" alt="" position="center" >}}

Serializable is the highest isolation level, in addition to repeatable-read, it also guarantees that during the current transaction lifetime, no other transactions will be able to add new records or remove records from the result sets used by the queries of the current transaction. In other words, serializable can prevent phantom read.

```sql
-- Start a transaction
BEGIN;

-- First query, this will lock the table, other transactions
-- will not be able to add or delete record if the id is less than 9999
SELECT 'name' FROM 'acid'.'example' WHERE 'id' < 9999;

-- Other queries
-- etc.

-- The amount of result is not changed
SELECT 'name' FROM 'acid'.'example' WHERE 'id' < 9999;

-- Commit transaction
COMMIT;
```

#### Dirty-read

Dirty-read is the lowest level of isolation, at this level there is no isolation whatsoever.

### D stands for Durability

{{< image src="/img/cap-acid-base/acid-durable-light.en.svg" alt="" position="center" >}}

`Durability` is a property that tells how reliable a database is against faults. This property guarantees that if a transaction is committed successfully, the committed data will persist (of course, given that the hard drive is not damaged) even if the database crashes right after the commit. This guarantee is ensured by using techniques like two-phase commit, backup, or replication. In MySQL, with every commit the database will first write data to the binlog before writing data into pages on disk, this ensures that in case of failures, MySQL can still recover using the binlog. The binlog is also used to replicate data between multiple nodes. In MongoDB, similar to binlog exists oplog.

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
