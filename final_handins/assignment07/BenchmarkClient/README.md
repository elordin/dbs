## Benchmarking

The benchmarking client allows to specify URLs, a number of Clients and a frequency at which the clients send requests to the URLs and a probability with which the URLs are selected.

In `application.conf` e.g.:

```
benchmark {
    n = 10,
    t = "100 millis",
    deadline = "30 seconds"
    queries = [
        {
            name: "Q1"
            uri: "http://localhost:3000/q1",
            propability: 0.25
        }
    ]
}

```

where `n` is the number of clients,

`t` is the average time between requests,

`deadline` is the total runtime of the benchmarking process

and `queries` is a list of queries


Like the generator it uses Scala. Run it using sbt with
```
sbt run
```
