+++
title = "Data Normalization in Relational Databases"
date = "2025-05-08T20:25:00+07:00"
lastmod = "2025-05-09T22:28:00+07:00"
author = "trviph"
cover = ""
tags = ["data-normalization", "database-design", "relational-databases", "sql", "normal-forms", "data-modeling", "database-theory"]
keywords = ["data normalization explained", "relational database normalization", "1NF database", "first normal form", "2NF database", "second normal form", "functional dependency database", "partial dependency", "database anomalies", "insert anomaly", "update anomaly", "delete anomaly", "database redundancy", "database consistency", "normalization vs denormalization", "database performance trade-offs", "SQL database design", "database normal forms tutorial"]
showFullContent = false
readingTime = true
hideComments = false
toc = true
+++

As software engineers, we deal with data abstraction every day. Trying to make sense of fuzzy real-world concepts and abstract them into structured information such as variables, functions, classes, structs, etc. that can be processed by software. Working with data almost always involves storing them into some sort of data storage, one such type of storage is relational databases, often called SQL databases. In this post we will take a ride through the normal forms, from the first to fourth, of relational database to learn what they are, why they are good, and why they can be bad.

## First normal form

Now we will dive into the foundation of the normal forms, the first normal form (1NF). The first normal form is satisfied only when no column within the table contains multiple values. More formally, all the columns must only contain a single atomic value. There must not exist any more meaningful facts about the data by taking a subset of a single column. There are several types of non-atomic columns:

### Repeating group

A repeating group refers to a column within a table that contains a set, list, or array of values. The column can be in any format, as long as it is interpreted as a list, then it is a repeating group. The example below contains a repeating group, i.e. non-atomic column, a violation of the 1NF.

```text
[user_information]
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

The `phone_numbers` contains a comma-separated value of multiple phone numbers. This format is fine as long as we don't run any queries on it, but that is often not the case. Eventually, we would want to run a query to check, say, how many phone numbers started with `(+01)` or to check if a particular phone number is already taken. Making such queries is non-trivial often involving string matching or parsing.

In addition, this format can lead to data redundancy. For instance, if the phone number is allowed to be shared between multiple users (accounts), the same phone number has to be stored in multiple places, making it redundant, taking up more spaces. Then, how can we normalize this? Let's see the table below.

```text
[user_information]
-------------------------
| user_id | signup_date |
-------------------------
|       1 |  2025-04-21 |
|       2 |  2025-04-21 |
|       3 |  2025-04-21 |
|       4 |  2025-04-21 |
|       5 |  2025-04-21 |
-------------------------

[user_phone_numbers]
----------------------------
| user_id | phone_number   |
----------------------------
|       1 | (+84) 001      |
|       1 | (+84) 002      |
|       2 | (+10) 012      |
|       4 | (+11) 002      |
----------------------------
```

We have now split the `phone_numbers` column into a separate table. The two tables are connected by the `user_id`, which helps reduce data redundancy and satisfies the 1NF. Originally, the 1NF refers to repeating groups as columns that hold an array as their value, but it also can include cases where there is a group of columns that represent the same attribute, like the example below.

```text
[user_information]
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

The example had two columns named `phone_number_1` and `phone_number_2`, representing the same attribute of the table, which is phone numbers. They are, however, single-value columns, so strictly speaking, it is not a violation of the 1NF. But it is considered to be an anti-pattern in schema design. This design only allows two phone numbers. What if we want more? It will also cause the data to be sparse, where only a small number of users have two phone numbers, while the majority only have one, causing a waste of storage space. Because of this, some literature also considers this to be a violation of the 1NF.

### Table as an attribute

```text
[user_information]
-------------------------------------------------
| user_id | name     | children                  |
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

Another example of a multiple-value column is using another table or a subset of a table as a column. Looking at the example above, you would be thinking that this is impossible, because most (if not all) relational databases disallow this kind of behavior. You would be right, the above example used to be impossible, but now with more and more relational databases allowing JSON as a type, it is conceptually possible to use a table as a column. Look at the example below, although in a different format, they represent the same meaning.

```text
[user_information]
------------------------------------------------------
| user_id | name     | children                       |
------------------------------------------------------
|       1 | John Doe | {"id": 3, "name": "Doe Doe" } |
|       2 | Jane Doe | {"id": 3, "name": "Doe Doe" } |
|       3 | Doe Doe  | null                          |
------------------------------------------------------
```

Storing data like above violates the 1NF because `children` is a non-atomic column causing the data to be redundant. When we need to update `Doe Doe` data, we would also need to update `Doe Doe` data for `John Doe` and `Jane Doe`. If not done carefully, it can cause inconsistencies in the data. To comply with the 1NF, we can re-model the table like the following example.

```text
[user_information]
----------------------
| user_id | name     |
----------------------
|       1 | John Doe |
|       2 | Jane Doe |
|       3 | Doe Doe  |
----------------------

[user_children]
----------------------
| user_id | child_id |
----------------------
|       1 |        3 |
|       2 |        3 |
----------------------
```

We now have a new table representing the relationship between entities. Now, every time `Doe Doe` data changes, we don't have to worry about updating the same data for `John Doe` or `Jane Doe`. Moreover, we can now easily query or modify relationships without the need for complex string matching and/or parsing. We can also model a more fine-grained table like below (note that more fine-grained != better).

```text
[user_information]
----------------------
| user_id | name     |
----------------------
|       1 | John Doe |
|       2 | Jane Doe |
|       3 | Doe Doe  |
----------------------

[user_relationships]
---------------------------------------
| user_id | relation  | other_user_id |
---------------------------------------
|       1 | parent_of |             3 |
|       2 | parent_of |             3 |
|       3 |  child_of |             1 |
|       3 |  child_of |             2 |
---------------------------------------
```

That being said, having JSON columns like mentioned above violates the 1NF. It is, however, not entirely a bad thing to do. In some use cases, it is preferable to denormalize data in exchange for an improvement in reading speed. This technique is embedding data, which stores a snapshot of any relevant data together with the main data to bypass joining or needing multiple queries, but may introduce inconsistency due to stale snapshots. It is up to us to choose the appropriate tool for the job.

### Number of attributes is not fixed

With JSON, there is another way to violate the 1NF: tables with a variable number of properties.

```text
[user_information]
--------------------------------------------------------------------------------------
| user_id | name     | misc_info                                                     |
--------------------------------------------------------------------------------------
|       1 | John Doe | {"date_of_birth": "2000-01-01"}                               |
|       2 | Jane Doe | {"date_of_birth": "2000-01-01", "hobbies": ["read", "write"]} |
|       3 | Doe Doe  | {"hobbies": ["running"]}                                      |
--------------------------------------------------------------------------------------
```

With the above example, can we say that `John Doe` has three properties just like `Jane Doe` and `Doe Doe`, which are `user_id`, `name`, and `misc_info`? Or is it `John Doe` that has three properties: `user_id`, `name`, and `date_of_birth` while `Jane Doe` has four properties: `user_id`, `name`, `date_of_birth`, and `hobbies`? In the former case, we treat the `misc_info` as a single atomic value, so there is no violation of 1NF. But in the latter case, it is a clear violation, making the table much more complex to query and manage, and prone to data discrepancies.

With all that being said, we may be tempted to think that JSON is evil. But it was also explained that it totally depends on how we use it. If we use a JSON column as an atomic value, then it is generally fine, but if we start to treat each key/value pair within the JSON as an independent property (e.g., treating `date_of_birth` inside `misc_info` as if it were a regular `date_of_birth` column for the user), it may cause long-term issues down the road as the data model evolves and becomes more complex as the system grows.

### The upside

The whole deal of 1NF is to eliminate repeating groups and multiple value columns. The examples have shown clearly (I hope you think so!) that using such a structure can lead to a conceptually complex data model, and complex queries later on in development. Also, 1NF helps with inconsistency issues by reducing data redundancy, fewer places we need to update for the same piece of data, a higher chance that the piece of data is consistent in the entire database (`Doe Doe` information is the same no matter which table we look at).

This will be the point that will be repeated over and over again when talking about the benefits of the normal forms in this post. Because after all, the main reason for their existence is to do just that, improving data consistency by reducing data redundancy and data anomalies (insert anomalies, update anomalies, delete anomalies).

### The downside

Although it helps prevent inconsistency and simplify data model design, 1NF is not without flaws. As we mentioned, sometimes it is more performant to embed data directly than to create data references, which 1NF implicitly encourages. In fact, some NoSQL databases actually encourage embedding over referencing, MongoDB is one such example. The first normal form also isn't friendly to use with tree-like data structures, often requires complex self-joins together with implementation of techniques like path enumeration, nested set, adjacency list or multiple queries to the database, and joins on the application level.

These criticisms, however, are not unique to 1NF but are applicable to the higher normal forms aswell. Because normal forms encourage splitting data into atomic tables whenever possible, making them often requires multiple JOINs, possible to slow down read queries. Moreover by using referential keys, it is complicated to scale (shard) the data into multiple physical locations while also ensuring the keys' integrity.

## Functional dependency

I found it hard going into the next normal forms without fully knowing what a functional dependency is. After all, it is the essence that the second and third normal forms are trying to reinforce. Let's see what it is all about.

Formally, a property `A` is functionally dependent on a property `B` (`B` -> `A`), only when in any given point in time, there exists only a single mapping from `B` to `A`, meaning by knowing `B` we can always infer what `A` is.

```text
[books]
----------------------------------------------------------------
| isbn   | author   | title                                    |
----------------------------------------------------------------
| 000001 | John Doe | John Doe's Introduction to Life          |
| 000002 | John Doe | John Doe's Introduction to Life (Vol. 2) |
| 000003 | Jane Doe | How to Laugh!                            |
| 000004 | Jane Doe | The Memory.                              |
----------------------------------------------------------------
```

In the above example, we can see, `title` is functionally dependent on `isbn` (`isbn` -> `title`) because given any `isbn` we can easily infer the `title`. Similarly, the `author` is also functionally dependent on `isbn` (`isbn` -> `author`). But `title` is **not** functionally dependent on `author`, why? Because given any `author`, we cannot uniquely identify a `title`. Say, by referring to `Jane Doe`, we can either get `How to Laugh!` or `The Memory` as the `title`. Naturally, we can say that `author` and `title` are functionally dependent on `isbn` or `isbn` -> [`author`, `title`], we can infer `author` and `title` by using the `isbn`.

### Full functional dependency

Formally, assume that a property `A` is already functionally dependent on a property (or set of properties) `B` (`B` -> `A`). For `A` to be **fully** functionally dependent on `B`, there must be no cases where `A` is also functionally dependent on a proper subset of `B`.

In practice, full functional dependency is used in contexts where composite keys are present. For a property to be fully functionally dependent on the composite key, it must not provide any fact to any subset of the composite key.

```text
[ratings]
-----------------------------------------
| isbn   | user_id | user_name | rating |
-----------------------------------------
| 000001 |   00002 | A. Readr  |      4 |
| 000001 |   00001 | Avid R.   |      5 |
| 000002 |   00002 | A. Readr  |      3 |
-----------------------------------------
```

Let's look at the above example, assume that `isbn` and `user_id` are a composite key. We can say that `rating` is functionally dependent on `isbn` and `user_id` (`isbn`, `user_id` -> `rating`) because with any given combination of `isbn` and `user_id` we can only get one single value of `rating`. Moreover, `rating` is considered to be fully functionally dependent on `isbn` and `user_id`, because by using either `isbn` or `user_id` alone we will get multiple values of `rating`. A book with `isbn` of `000001` has two ratings of `4` and `5` by two different users, and the `user_id` of `00002` also gives two ratings of `4` and `3` to two different books.

### Partial functional dependency

Formally, assume that a property `A` is already functionally dependent on a property (or set of properties) `B` (`B` -> `A`). For `A` to be **partial** functionally dependent on `B`, it **must not** be fully functionally dependent on `B`.

```text
[ratings]
-----------------------------------------
| isbn   | user_id | user_name | rating |
-----------------------------------------
| 000001 |   00002 | A. Readr  |      4 |
| 000001 |   00001 | Avid R.   |      5 |
| 000002 |   00002 | A. Readr  |      3 |
-----------------------------------------
```

Still using the same example in [full functional dependency](#full-functional-dependency) section, under the same assumption that `isbn` and `user_id` are a composite key, but now let's focus on `user_name` instead of `rating`. Just like with `rating`, we can say that `user_name` is functionally dependent on `isbn` and `user_id` (`isbn`, `user_id` -> `user_name`) because with any given combination of `isbn` and `user_id` we can only get one single value of `user_name`. But **unlike** `rating`, `user_name` **is not** fully functionally dependent on `isbn` and `user_id`. Because by using just `user_id`, a proper subset of `isbn` and `user_id` composite key, we can uniquely infer the `user_name`. In other words, `user_name` is also functionally dependent on `user_id`, this is a partial functional dependency.

## Second normal form

A table satisfies the second normal form (2NF) only when:

- It already satisfies the first normal form.
- There is no partial dependency between the key and any non-key columns in it.

So why does the second normal form not allow partial functional dependency? Because it causes data redundancy, a.k.a. duplicate data. Let's revisit the example described in the [functional dependency](#functional-dependency) section.

```text
[ratings]
-----------------------------------------
| isbn   | user_id | user_name | rating |
-----------------------------------------
| 000001 |   00002 | A. Readr  |      4 |
| 000001 |   00001 | Avid R.   |      5 |
| 000002 |   00002 | A. Readr  |      3 |
-----------------------------------------
```

As discussed before, we can see that `user_name` is partially dependent on `user_id`, which makes it a 2NF violation. The bad thing about this is that it enables the `user_name` data to be redundant. When we try to update the name of a user, say `user_id` is `00002`, we would need to update the name in multiple records. This is an update anomaly. We may argue that, in this case, data redundancy is not a real problem, because it will not cause inconsistency issues since the SQL query for such an update is guaranteed to be atomic.

```sql
UPDATE 'ratings'
SET
    'user_name' = "A whole new name"
WHERE
    'user_id' = '00002';
```

But the problems can go beyond just inconsistency issues, they can lead to the loss of data. For example, consider the user `00099`. Since they have not rated any book yet in the non-normalized table, we have no way to know their `user_name`. This is an insert anomaly. Similarly, if user `00001` deletes their only rating, we lose the information that their `user_name` is `Avid R.`. This is a delete anomaly.

On a more practical standpoint, an update anomaly may also slow down write speed. Since multiple records need to be updated, the database may need to load multiple physical files and update them all, leading to more rows needing to be locked, more pages or indexes needing to be scanned, using more resources (CPU, RAM). With all that being said, how do we transform this example so that it satisfies the 2NF?

```text
[ratings]
-----------------------------
| isbn   | user_id | rating |
-----------------------------
| 000001 |   00002 |      4 |
| 000001 |   00001 |      5 |
| 000002 |   00002 |      3 |
-----------------------------

[user_information]
-----------------------
| user_id | user_name |
-----------------------
|   00001 | Avid R.   |
|   00002 | A. Readr  |
|   00099 | Anon U.   |
-----------------------
```

We now separate the previous table into two separate tables, one stores the ratings, another stores the user information. With this structure, we eliminate the partial dependency between the `user_id` and `user_name`, making them satisfy the 2NF. The benefit is now every time we need to update the user information, we only need to update one record in the user information table, eliminating update anomalies. And even without ratings, we still know user `00099` information, which eliminates the insert anomaly. The delete anomaly was also eliminated as user `00001` can now delete their ratings without causing any loss of the user information.

Since the 2NF encourages splitting a single table into multiple tables to eliminate partial dependency. It may have an impact on read performance. We assume that with every rating, we also need to know the name of the person who did the rating. It is reasonable to store the `user_name` together with the ratings, especially if this rating is queried very often, removes the need to join tables frequently. We may design the tables like the following.

```text
[ratings_with_user_name]
-----------------------------------------
| isbn   | user_id | user_name | rating |
-----------------------------------------
| 000001 |   00002 | A. Readr  |      4 |
| 000001 |   00001 | Avid R.   |      5 |
| 000002 |   00002 | A. Readr  |      3 |
-----------------------------------------

[user_information]
-----------------------
| user_id | user_name |
-----------------------
|   00001 | Avid R.   |
|   00002 | A. Readr  |
|   00099 | Anon U.   |
-----------------------
```

With this structure, it ensures no insert or delete anomaly, but it reintroduces the update anomaly. The trade-off of such a de-normalized structure is that it may improve read performance while possibly degrading write performance and can lead to inconsistent data. It is ultimately dependent on the use case for us to decide which is the best approach for this kind of trade-off.

## To be continued

## References

- E. F. Codd, "A relational model of data for large shared data banks", [dl.acm.org](https://dl.acm.org/doi/10.1145/362384.362685)
- E. F. Codd, "Normalized data base structure: a brief tutorial", [dl.acm.org](https://dl.acm.org/doi/10.1145/1734714.1734716)
- Ronald Fagin, "Multivalued dependencies and a new normal form for relational databases", [dl.acm.org](https://dl.acm.org/doi/10.1145/320557.320571)
- William Kent, "A Simple Guide to Five Normal Forms in Relational Database Theory", [www.bkent.net](https://www.bkent.net/Doc/simple5.htm)
- Wikipedia, "First Normal Form", [en.wikipedia.com](https://en.wikipedia.org/wiki/First_normal_form)
- Wikipedia, "Second Normal Form", [en.wikipedia.com](https://en.wikipedia.org/wiki/Second_normal_form)
- Wikipedia, "Third Normal Form", [en.wikipedia.com](https://en.wikipedia.org/wiki/Third_normal_form)
- Wikipedia, "Fourth Normal Form", [en.wikipedia.com](https://en.wikipedia.org/wiki/Fourth_normal_form)
- MongoDB, "Embedding MongoDB", [www.mongodb.com](https://www.mongodb.com/resources/products/fundamentals/embedded-mongodb)
- Cassandra, "Data Modeling", [cassandra.apache.org](https://cassandra.apache.org/doc/latest/cassandra/developing/data-modeling/index.html)
