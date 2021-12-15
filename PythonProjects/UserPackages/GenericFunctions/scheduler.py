import os
import sys
import traceback
import enum

from GenericFunctions.utility import CoolUtility
#import GenericFunctions.time
#from GenericFunctions.time import TimeDateHandler

# General description
# Developed and tested on Python 3.6

class EnumPathFormat(enum.IntEnum):
    PATHFORMAT_DEFAULT = 1

class Scheduler:
    # This is a class variable shared by ALL instances (Similar to a static Java-variable?)
    moduleName = "Threadhandler Class"

    def __init__(self, fileObject, fileName, filePath):
        self.name = "Threadhandler"
        #self.utility = CoolUtility()

#A Threadpool is specific number of logical threads available for workload assignment by the application/scheduler.
class ThreadPool:
    # This is a class variable shared by ALL instances (Similar to a static Java-variable?)
    moduleName = "Threadhandler Class"

    def __init__(self, fileObject, fileName, filePath):
        self.name = "Threadhandler"
        #self.utility = CoolUtility()

#Threads are used to parallelize applicationspecific workloads from within the current application context.
class Threadhandler:
    # This is a class variable shared by ALL instances (Similar to a static Java-variable?)
    moduleName = "Threadhandler Class"

    def __init__(self, fileObject, fileName, filePath):
        self.name = "Threadhandler"
        #self.utility = CoolUtility()

#Processes are actual os specific applications or own implementations that should run as a seperate application process.
class Processhandler:
    # This is a class variable shared by ALL instances (Similar to a static Java-variable?)
    moduleName = "Processhandler Class"

    def __init__(self, fileObject, fileName, filePath):
        self.name = "Processhandler"
        #self.utility = CoolUtility()
