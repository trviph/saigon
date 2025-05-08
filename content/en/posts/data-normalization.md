+++
draft = true
title = "Data Modeling - Normalization"
date = "2025-05-08T20:25:03+07:00"
author = "trviph"
cover = ""
tags = ["data-modeling", "data-consistency", "data-redundancy"]
keywords = ["data-modeling", "data-consistency", "data-redundancy"]
showFullContent = false
readingTime = true
hideComments = false
toc = true
+++

Abstraction has always been a core concept in software engineering, not only relevant as an OOP principle but in the entire industry. It is hard to do abstraction well; we all have to deal with or make terrible abstractions, think about all those pyramids of inheritance or the demon web of "microlith" services. Abstraction is a broad topic. Abstract what, exactly? Is it code, system, hardware, or something else entirely?

We will be discussing data abstraction, commonly known as data modeling. As software engineers, we often have to translate fuzzy, real-world concepts into some kind of structured information (classes, attributes, methods, variables, functions) that can be understood and processed by the software. Think about representing a "person", depending on the context, they might become a "user", an "employee", a "seller", or something else entirely, each with different properties. This is the first layer of data modeling, extracting a discrete set of attributes from the real-world representation. We also won't be discussing this layer here, because it is too broad and often depends heavily on the problem we try to solve, and the domain knowledge we possess.

> However, if you are interested, check out "Data and Reality" by William Kent. The book touches upon this level of data modeling and is very interesting to read. I am not affiliated by any means, just thought that it is a good read and should be shared.

Instead, we will be discussing the next layer, how to translate these abstracted entities into a data format to be easily stored, managed, and understood, specifically into SQL tables, by exploring the famous Normal Forms.

## First normal form

Now we will dive into the foundation of the normal forms, the first normal form (1NF). The first normal form is satisfied only when no column within the table contains multiple values. More formally, all the columns must only contain a single atomic value. There must not exist any more meaningful facts about the data by taking a subset of a single column. There are several types of non-atomic columns:

### Repeating group

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

A repeating group refers to a column within a table that contains a set, list, or array of values. The column can be in any format, as long as it is interpreted as a list, then it is a repeating group. The example table above has a repeating group, which is `phone_numbers`, containing a comma-separated value of multiple phone numbers. This format is fine as long as we don't run any queries on it, but that is often not the case. Eventually, we would want to run a query to check, say, how many phone numbers started with `(+01)` or to check if a particular phone number is already taken, or in case the phone number is allowed to be shared between multiple users (accounts), the same piece of information has to be stored multiple times, making it redundant, taking up more spaces. Then, how can we improve this? Let's see the table below.

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

We have now split the `phone_numbers` column into a separate table. The two tables are connected by the `user_id`, which helps reduce data redundancy and satisfies the 1NF. Originally, the 1NF refers to repeating groups as columns that hold an array as their value, but it also can include cases where there is a group of columns that represent the same attribute, like the example below.

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

The example had two columns named `phone_number_1` and `phone_number_2`, representing the same attribute of the table, which is phone numbers. They are, however, single-value columns, so strictly speaking, it is not a violation of the 1NF. But it is considered to be an anti-pattern in schema design. This design only allows two phone numbers. What if we want more? It will also cause the data to be sparse, where only a small number of users have two phone numbers, while the majority only have one, causing a waste of storage space. Because of this, some literature also considers this to be a violation of the 1NF.

### Table as an attribute

```text
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
------------------------------------------------------
| user_id | name     | children                       |
------------------------------------------------------
|       1 | John Doe | {"id": 3, "name": "Doe Doe" } |
|       2 | Jane Doe | {"id": 3, "name": "Doe Doe" } |
|       3 | Doe Doe  | null                          |
------------------------------------------------------
```

Storing data like above violates the 1NF because it causes the data to be redundant. When we need to update `Doe Doe` data, we would also need to update `Doe Doe` data for `John Doe` and `Jane Doe`. If not done carefully, it can cause inconsistencies in the data. To comply with the 1NF, we can re-model the table like the following example.

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

We now have a new table representing the relationship between entities. Now, every time `Doe Doe` data changes, we don't have to worry about updating the same data for `John Doe` or `Jane Doe`. Moreover, we can now easily query or modify relationships without the need for complex string matching and/or parsing. We can also model a more fine-grained table like below (note that more fine-grained != better).

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

That being said, having JSON columns like mentioned above violates the 1NF. It is, however, not entirely a bad thing to do. In some use cases, it is preferable to sacrifice writing speed (create, update, delete) in exchange for reading speed (select, aggregate). This technique is embedding data, which stores a snapshot of any relevant data together with the main data to bypass joining or needing multiple queries. It is up to us to choose the appropriate tool for the job.

### Number of attributes is not fixed

With JSON, there is another way to violate the 1NF: tables with a variable number of properties.

```text
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

The whole deal of 1NF is to help us produce a simpler data model that is easy to understand, query, manage, and extend. By enforcing atomicity on column values and eliminating repeating groups, leading to better data consistency and much less data duplication.

### The downside

Although it helps prevent inconsistency and simplify data model design, 1NF is not without flaws. As we mentioned, sometimes it is more performant to embed data directly than to create data references, which 1NF implicitly encourages. In fact, some NoSQL databases actually encourage embedding over referencing, MongoDB is one such example. The first normal form also isn't friendly to use with tree-like data structures, often requires complex joins or multiple queries to the database, and joins on the application level.

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
