+++
title = "Dual Write"
date = "2025-03-05T19:27:42+07:00"
author = "trviph"
tags = ["backend", "data-consistency"]
keywords = ["backend", "data-consistency"]
description = "Discussing about dual write and its problems, also introducing some patterns to mitigate them."
showFullContent = false
readingTime = true
color = "paper"
+++

# Introduction

While working with backend systems, there is a common pattern when handling incoming data.
We usually have a server waiting to receive data from a message broker or an API.
When the data arrives, we process the data based on the business contract and then insert
or update that data into the database, before also transmitting the data to the next server
via a message broker or an API.

{{< image src="/img/dual-write/intro-light.en.svg" alt="" position="center" >}}

# Read More

- https://www.confluent.io/blog/dual-write-problem/
- https://newsletter.systemdesignclassroom.com/p/i-have-seen-this-mistake-in-production
- https://microservices.io/patterns/data/transactional-outbox.html
- https://debezium.io/blog/2020/02/10/event-sourcing-vs-cdc/
