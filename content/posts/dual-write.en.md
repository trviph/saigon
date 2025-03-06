+++
title = "Dual Write"
date = "2025-03-05T19:27:42+07:00"
author = "trviph"
tags = ["backend", "data-consistency"]
keywords = ["backend", "data-consistency"]
cover = "/img/dual-write/intro-light.en.svg"
coverCaption = ""
showFullContent = false
readingTime = true
color = "paper"
+++

While working with backend systems, there is a common pattern when handling incoming data.
We usually have a server waiting to receive data from a message broker or an API.
When the data arrives, we process the data based on the business contract and then insert
or update that data into the database before also transmitting the data to the next server
via a message broker or an API. This data processing pattern is called a dual write,
sometimes also called multi-write or sync-write.

# Problem

This pattern seems to be pretty intuitive, so what is its problem?
The main problem with this pattern is that it is prone to failures that can often lead to
data inconsistencies, which require hair-pulling debug sessions to *maybe* identify the cause.

{{< image src="/img/dual-write/failure-light.en.svg" alt="" position="center" >}}

The problem arises after we successfully save the processed data to the database
but fail at sending the data to the message broker or next server. This caused the data to be
inconsistent across multiple systems because the data have now been updated in our system but
all the downstream systems are unaware of this update.

There are multiple possible reasons for this failure to occur. Maybe there was a network partition
happening at the time, causing the receiver of data to be unreachable, or the receiver simply having
downtime due to errors or maintenance, or it was something as simple as human errors sending
a wrong schema to a wrong API, etc. But whatever the cause, the data is now mismatched and we must
somehow fix it.

## Examples of Dual Write in E-commerce

In e-commerce systems, to easily scale out the overall systems and engineering teams. The architect is often
separated into several services with defined boundaries. Some of the most crucial services,
you may find in these systems are a payment service/gateway to handle customer payments and the checkout
process; an order management system to manage and track customer orders; an inventory management system
for sellers to manage their products, stock, storage, etc.; a search service to allow buyers to browse,
search and filter products based on their queries, interest, history, etc.

{{< image src="/img/dual-write/ecommerce-checkout-light.en.svg" alt="" position="center" >}}

During checkout, after the customer successfully pays for their orders using the payment service.
The payment service has to tell the order management system that the order has been paid for, and
the order should proceed to the next step. However, since the payment service failed to send this data, the
order has been stuck, causing the user to wait before they realize what happened and have to contact
customer support, a poor user experience.

{{< image src="/img/dual-write/ecommerce-listing-creation-light.en.svg" alt="" position="center" >}}

During listing creation, after the seller successfully creates a new product listing for their product.
The inventory management system will notify the search service so that it will begin to create a new entry
in its database, doing some indexing work to optimize the search performance and allow the listing to
be searchable. However, if the inventory management system fails to notify the search service,
the listing will never be visible and the seller will lose their potential customer and income.
This can possibly damage the reputation of the e-commerce platform among sellers.

# Some Solutions that Do not Work

Now that we know what dual writing is and the problems it brings, let's discuss some solutions
and why they won't work.

## Revert the Data Back

Can we revert the data back? Yes, but a revert is also a fallable operation,
so what if the revert also fails, not to mention we have to store some kind of state before reverting.

How about not committing to the database unless we succeed in notifying the downstream services,
we won't need to store any state then? A commit is also a fallable operation.

In my humble opinion, this approach gets messy really quickly.

## Save after Sent

How about we only write the data to the database if we succeed in sending it to downstream services?
This approach is similar with committing after sent we have discussed above, a write to the database
is not guarantee to success. Simply switching the order of operations solve nothing.

## Retry again

If there is a failure retrying again seems to be a good enough solution.
But let's consider how many times we should retry and what is the interval between them?

If the receiver is down for a long time, say more than five minutes, most retry configurations
would have been given up by then. And after giving up, the data would still be inconsistent in our system.
We need to think up a better solution.

What if we increase the retry duration by using some techniques `exponential backoff`?
This could work but what if *our* service fails and crashes while retrying? By the next time,
it is up again, we will surely lose the context of what we were trying to do.
We will need to store some kind of state for this approach to work. We are getting closer.

# Some Solutions that Do Work

In this section, we will be listing some patterns to handle the dual write properly.
We won't go into any details here, other than just listing their names so we are made aware
of their existence since this post is quite long already. I may write up more posts about them.
But for now, if you want to learn more, you have to do it on your own. These patterns are called:

- Transactional Outbox Pattern
- Listen to Yourself Pattern
- Change Data Capture Pattern

# Read More

- https://www.confluent.io/blog/dual-write-problem/
- https://newsletter.systemdesignclassroom.com/p/i-have-seen-this-mistake-in-production
- https://microservices.io/patterns/data/transactional-outbox.html
- https://debezium.io/blog/2020/02/10/event-sourcing-vs-cdc/
- https://developers.redhat.com/articles/2021/09/21/distributed-transaction-patterns-microservices-compared
