% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/method-ml.data.frame.R
\name{as.ml.data.frame}
\alias{as.ml.data.frame}
\title{Upload data in a data.frame object or create data based on a \link{ml.data.frame} object}
\usage{
as.ml.data.frame(conn, x, name, format = "json", directory = "")
}
\arguments{
\item{conn}{A ml.conn object that has a valid connection to a MarkLogic Server}

\item{x}{a Data Frame or ml.data.frame object.}

\item{name}{The name of the object.}

\item{format}{The format od the documents that is created, json or XML. Default is json}

\item{directory}{The directory to save the documents, needs to start and end with a /. Default saved to /rfml/[username]/[name]/}
}
\value{
A ml.data.frame object.
}
\description{
The function will upload the data within a data.frame object or create data in MarkLogic Server
based on a \link{ml.data.frame} object. Data created based on \link{ml.data.frame} will be flat and
fields will have the same names as in the .col.name slot. See details for more information about how
data is created.
}
\details{
When data is uploaded or created it will be stored as json documents default, the format parameter controls, and
Document URIs, the identifier of a document, is generated based on the string "rfml", the rowname if a data.frame
or a counter if it is a ml.data.frame, the loged in username and the name parameter, for example /rfml/admin/iris/.
The documents will also belong to a collection named after tne name parameter.
}
\examples{
\dontrun{
 library(rfml)
 ml.connect()
 # create a ml.data.frame based on the iris data set
 mlIris <- as.ml.data.frame(iris, "iris")
}
}
\seealso{
\code{\link{ml.data.frame}}, \code{\link[rfml]{as.data.frame}} for pulling data, \code{\link{rm.ml.data.frame}} for delete uploaded data
}
\concept{
array
}

