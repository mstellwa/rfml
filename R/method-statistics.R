# Copyright (c) 2015 All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# Various statistics methods

#' Correlation
#'
#' Returns the Pearson correlation coefficient of a data set. The size of the input
#' should be 2.
#'
#' The function eliminates all pairs for which either the first element or the second
#' element is empty. After the elimination, if the length of the input is less than 2,
#' the function returns the empty sequence. After the elimination, if the standard
#' deviation of the first column or the standard deviation of the second column is 0,
#' the function returns the empty sequence.
#'
#' @export
setMethod(f="cor", signature=c(x="ml.col.def",y="ml.col.def"),

          function(x,y,use = NULL,method = NULL ) {

            # use
            if (!missing(use) && !is.null(use))
             stop(simpleError("use option is not implemented yet"))

             # method
            if (!missing(method) && !is.null(method))
               stop(simpleError("method option is not implemented yet"))

            if(x@.parent@.name!=y@.parent@.name) {
               stop("Cannot combine two columns from different ml.data.frames.")
            }
            if(x@.data_type!="number" || y@.data_type != "number") {
              stop("Can only columns of number type")
            }
#             ####### Identifying Numeric Fields #########
#             res <- idaTableDef(x,F)
#             xCols <- as.vector(res[res$valType=='NUMERIC','name'])
#
#             # Check if any columns are left in the end
#             if (!length(xCols))
#               stop("nothing to calculate")
#
#             xMean<-idaMean(x,xCols)
#             n<-NROW(x)
#             queryList <- c();
#
#
#             if (!missing(y) && !is.null(y)){
#
#               if (!is.ida.data.frame(y))
#                 stop("cor is valid only for ida.data.frame objects")
#
#               if(idadf.from(x)!= idadf.from(y))
#                 stop("x and y must be from the same database table")
#
#               ####### Identifying Numeric Fields #########
#               res <- idaTableDef(y,F)
#               yCols<- as.vector(res[res$valType=='NUMERIC','name'])
#
#
#               # Check if any columns are left in the end
#               if (!length(yCols))
#                 stop("nothing to calculate")
#
#               yMean<-idaMean(y,yCols)
#
#               for(i in 1:length(xCols)) {
#                 for(j in 1:length(yCols)) {
#                   queryList <- c(queryList,paste("SUM((", paste("\"", xCols[i], "\"", collapse=",",sep=''),"-",xMean[i],")*(", paste("\"", yCols[j], "\"", collapse=",",sep=''),"-",yMean[j],"))/(SQRT(SUM((",paste("\"", xCols[i], "\"", collapse=",",sep=''),"-",xMean[i],")*(",paste("\"", xCols[i], "\"", collapse=",",sep=''),"-",xMean[i],")))*SQRT(SUM((",paste("\"", yCols[j], "\"", collapse=",",sep=''),"-",yMean[j],")*(",paste("\"", yCols[j], "\"", collapse=",",sep=''),"-",yMean[j],"))))",sep=''));
#                 }
#               }
#             }
#
#
#             else{
#               for(i in 1:length(xCols)) {
#                 for(j in i:length(xCols)) {
#                   queryList <- c(queryList,paste("SUM((", paste("\"", xCols[i], "\"", collapse=",",sep=''),"-",xMean[i],")*(", paste("\"", xCols[j], "\"", collapse=",",sep=''),"-",xMean[j],"))/(SQRT(SUM((",paste("\"", xCols[i], "\"", collapse=",",sep=''),"-",xMean[i],")*(",paste("\"", xCols[i], "\"", collapse=",",sep=''),"-",xMean[i],")))*SQRT(SUM((",paste("\"", xCols[j], "\"", collapse=",",sep=''),"-",xMean[j],")*(",paste("\"", xCols[j], "\"", collapse=",",sep=''),"-",xMean[j],"))))",sep=''));
#                 }
#               }
#               yCols<-xCols
#             }
#
#             queryList<-paste("SELECT ", paste(queryList,sep=',',collapse=',')," FROM ",idadf.from(x)," ",ifelse(nchar(x@where),paste(" WHERE ",x@where,sep=''),''),sep='');
#             cor<-idaQuery(queryList)
#             mdat <- matrix(1:(length(xCols))*(length(yCols)),nrow=length(xCols),ncol=length(yCols),dimnames = list(c(xCols),c(yCols)),byrow=T)
#
#             # Arrange matrix values
#             r <- 1;
#             c <- 1;
#             for(i in 1:ncol(cor)) {
#               mdat[r,c] <- cor[[i]][1];
#               if (is.null(y))
#                 mdat[c,r] <- mdat[r,c];
#               c <- c + 1;
#               if(c>length(yCols)) {
#                 r <- r+1;
#                 c <- if (is.null(y)) r else 1
#               }
#             }
#             mdat
        }
)
