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

{{< code language="css" title="Really cool snippet" id="1" expand="Show" collapse="Hide" isCollapsed="true" >}}
pre {
  background: #1a1a1d;
  padding: 20px;
  border-radius: 8px;
  font-size: 1rem;
  overflow: auto;

  @media (--phone) {
    white-space: pre-wrap;
    word-wrap: break-word;
  }

  code {
    background: none !important;
    color: #ccc;
    padding: 0;
    font-size: inherit;
  }
}
{{< /code >}}

```go
	import "fmt"

  // your code here
	func main() {
		fmt.Println("Hello, World!")
	}
```

# Read More

- https://www.confluent.io/blog/dual-write-problem/
- https://newsletter.systemdesignclassroom.com/p/i-have-seen-this-mistake-in-production
- https://microservices.io/patterns/data/transactional-outbox.html
- https://debezium.io/blog/2020/02/10/event-sourcing-vs-cdc/
