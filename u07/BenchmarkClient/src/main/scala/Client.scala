package benchmark

import akka.actor.ActorSystem

import scala.concurrent.duration._


import AggregationActor._


case class FailedResponse() extends Exception


object Client extends App {
    // args : Array[String]

    val system = ActorSystem("BenchmarkClient")

    val deadline = 20.seconds.fromNow

    val n = 2

    val t = 100.millis

    val queries = List(Q1, Q2, Q3, Q4, Q5, Q6)

    val aggregator = system.actorOf(AggregationActor.props( deadline, n, t, queries ), "aggregator")

}
