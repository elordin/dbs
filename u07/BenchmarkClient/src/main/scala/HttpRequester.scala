package benchmark

import akka.actor.{Actor, ActorRef, Props, Terminated, PoisonPill}
import akka.event.Logging
import akka.util.Timeout
import akka.pattern.ask
import akka.io.IO


import scala.concurrent.duration._
import scala.concurrent.Future

import scala.util.Random

import spray.can.Http
import spray.http._
import HttpMethods._


object HttpRequester {
    def props(deadline:Deadline, reaper:ActorRef, t:Duration, queries:List[Query]):Props =
        Props(new HttpRequester(deadline, reaper, t, queries))

}

class HttpRequester(
    deadline: Deadline,
    reaper: ActorRef,
    t: Duration,
    queries: List[Query]
) extends Actor {
    import Reaper._
    import AggregationActor._
    import context._

    implicit val timeout: Timeout = Timeout(10.seconds)


    val logging = Logging(context.system, this)

    def receive = {
        case _ => logging.error("Received unknown message.")
    }

    def getQuery:Query = {
        val pool = queries.flatMap( (q) => for (i <- 1 to q.prop) yield q )
        pool.apply(Random.nextInt(pool.size))
    }

    reaper ! WatchMe(self)

    while (!deadline.isOverdue) {

        val query:Query = getQuery

        val startTime = System.currentTimeMillis()
        val request: Future[HttpResponse] = (IO(Http) ? HttpRequest(GET, query.uri)).mapTo[HttpResponse]


        request onSuccess {
            case HttpResponse(status,_,_,_) if status.isSuccess =>
                val endTime = System.currentTimeMillis()

                if (context != null && context.parent != null)
                    context.parent ! Success(query, endTime - startTime)
            case HttpResponse(status,_,_,_) =>
                if (context != null && context.parent != null)
                    context.parent ! Failure("ERROR: Received " + status)

        }

        request onFailure {
            case e =>
                if (context != null && context.parent != null)
                    context.parent ! Failure(e.getMessage)
        }

        Thread.sleep(((Random.nextFloat * 0.4 + 0.8) * t.toMillis).toLong)
    }

    self ! PoisonPill
}
