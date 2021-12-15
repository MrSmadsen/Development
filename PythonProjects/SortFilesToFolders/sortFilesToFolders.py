import os
import sys
import datetime
import argparse
import traceback #This is not required in python 3.9. Test if import can be omitted in 2.x.

sys.path.append(os.path.normpath(os.path.abspath("..\\UserPackages")))
from GenericFunctions.file_path import EnumPathFormat
from GenericFunctions.file_path import FileAndPathHandler
from GenericFunctions.utility import CoolUtility
from GenericFunctions.utility import EnumProgressIndicator
from GenericFunctions.utility import EnumProgressDataFormat
from GenericFunctions.utility import EnumProgressRelativity
from GenericFunctions.time import TimeDateHandler
from GenericFunctions.time import TimeDurationMeasurement
from GenericFunctions.time import EnumDateTimeFormat

from PIL import Image
from PIL.ExifTags import TAGS

#General description
#Python class to copy or move files into folders based on OriginalCreationDate.
#Developed and tested on Python 3.6

# URGENT:

# Further functionality:
# Add unit test - Inspiration available in utility.py: stringIsEmpty() / testStringIsEmpty()

# Add workerThread to the application logic and a main thread to handle user input to the running application.
#    That will enable the user to stop the application and exit if required. Currently os based interruption has to be used.
#    Perhaps update the application to a python gui app and use the built in threading model to improve application behavior.

# Add os specific application support for windows-lock, hibernation etc. The application should be able to resume work if the os does os related stuff. Alternatively
# implement the copy-update functionality to avoid total restart of the application.
  # "Package: Programlogic"
  # "Package: User interface"
  # "Package: os interaction"

# Regular code maintenance notes:
# - Add support for custom defaultIncSeperator in file_path - incrementFileName(....)

class SortationHandler:
    # This is a class variable shared by ALL instances (Similar to a static Java-variable?)
    moduleName = "BackupHandler Class"

    def __init__(self, argv):
        self.name = "SortationHandler"
        self.sourceFolderArgvSupplied = False
        self.destinationFolderArgvSupplied = False
        self.useDefaultSourceFolder = False
        self.useDefaultDestinationFolder = False
        self.eventName = ''
        self.pathFormatChoices = {'1' : EnumPathFormat.PATHFORMAT_DEFAULT, '2' : EnumPathFormat.PATHFORMAT_SUBYEAR, '3' : EnumPathFormat.PATHFORMAT_SUBYEAR2, '4' : EnumPathFormat.PATHFORMAT_SUBYEARMONTH}
        self.conversionFactor = 1 # no conversion - Default datasize is bytes.

        # Timing
        startTime = 0
        endTime = 0

        self.pathFormat = 0
        self.filenameIncrement = False
        self.enableCopyFileUpdateOption = False
        self.moveFiles = False
        self.checkExifData = True
        self.checkOsStatResult = False

        #Filehandles
        self.invalidFilesOutputFile = None
        self.validFilesOutputFile = None
        self.sortingResultFile = None

        utility.myPrintMessage("\nFile Sortation program: Will sort files into folders.", paddingType=0)
        utility.myPrintMessage("Currently running on: " + sys.platform + "\n", paddingType=1)

        self.fileHandler = FileAndPathHandler()
        self.utility = CoolUtility()
        self.timing = TimeDurationMeasurement()
        self.timeDateHandler = TimeDateHandler()

        # Path folders. They are initialized by setupEnvironment().
        self.tempFolder = ''  # Directory in which to do the directory/files processing.
        self.sourceFolder = ''  # Directory in which the source files are stored.
        self.destinationFolder = ''  # Directory in which the sorted files are stored.
        self.baseFolder = os.path.normpath(os.path.abspath(os.path.curdir))

        self.timing.setupTimeMeasurementStartEndDelta(["initArgv", "startSortation"])

        startTime = self.timeDateHandler.getCurrentTime()
        parsedArgs = self.initArgv(argv)
        endTime = self.timeDateHandler.getCurrentTime()
        self.timing.storeMeasurementStartEndDelta("initArgv", startTime, endTime)

        if self.setupEnvironment(parsedArgs) is False:
            # self.cleanup()
            self.utility.systemExit(1, '\nExit')
        else:  # The application will return to main, from where the main thread will call generateTarArchive().
            pass

        startTime = self.timeDateHandler.getCurrentTime()
        self.startSortation()
        endTime = self.timeDateHandler.getCurrentTime()
        self.timing.storeMeasurementStartEndDelta("startSortation", startTime, endTime)

        self.timing.calculate()
        self.timing.displayDuration("initArgv")
        self.timing.displayDurationSummary()

    def initArgv(self, argv):
        parser = argparse.ArgumentParser(
            description="Utility to store files in folders based on original creation date.")

        #group = parser.add_mutually_exclusive_group()
        # The arguments in this group is mutually exclusive. If you choose one, the other is not allowed.
        #group.add_argument("-a", "--archive", type=str, help="Enable archive mode (no compression), usage: archive /path/")
        #group.add_argument("-x", "--extract", type=str, help="Enable extraction mode, usage: extract filename")

        # Optional arguments.
        parser.add_argument("-i",  "--inputpath", type=str, help="Input folder path. Default is basefolder/SortTheseFiles/")
        parser.add_argument("-o",  "--outputpath", type=str, help="Output folder path. Default is baseFolder/destination/")
        parser.add_argument("-e",  "--eventname", type=str, help="Optional name that will be appended on the folder names being created.")
        parser.add_argument("-f",  "--pathformat", type=str, help="Optional. Defines subfoldering. 1: \year - Day. Month. 2: Year\Month Day. 3: Year\Day. Month. 4: Year\Month\Day.")
        parser.add_argument("-n",  "--incrementfilenames", action="store_true", help="Optional. Eanbles auto filename incrementation if filename clashes are found.")
        parser.add_argument("-u",  "--enablecopyupdate", action="store_true",help="Optional. Eanbles distutils.file_utils.copy_file update parameter. The file is only copied if the destination is unavailable or older.")
        parser.add_argument("-m",  "--movefiles", action="store_true",help="Optional. Eanbles distutils.file_utils.move_file(....) instead of  distutils.file_utils.copy_file(....).")
        parser.add_argument("-de", "--disableexif", action="store_true",help="Optional. Disables exif data retrieval. The program will only use os file att. If exif is used it is prioritized over os file att.")
        parser.add_argument("-eo", "--enableosattributes", action="store_true",help="Optional. Enables os based data retrieval. If exif is used it is prioritized over os file att.")


        try:
            parsedArgs = parser.parse_args(argv)
        except Exception as e:
            self.utility.myPrintMessage('- error: ' + str(e), paddingType=0)
            parsedArgs = None

        if (parsedArgs is None):
            pass
        else:
            try:
                if (self.utility.stringIsEmpty(parsedArgs.inputpath, ignoreSpaces=False) is False):
                    self.sourceFolderArgvSupplied = True
                else:
                    self.sourceFolderArgvSupplied = False
            except TypeError as typeError:
                self.sourceFolderArgvSupplied = False

            try:
                if (self.utility.stringIsEmpty(parsedArgs.outputpath, ignoreSpaces=False) is False):
                    self.destinationFolderArgvSupplied = True
                else:
                    self.destinationFolderArgvSupplied = False
            except TypeError as typeError:
                self.destinationFolderArgvSupplied = False

            try:
                if (self.utility.stringIsEmpty(parsedArgs.eventname, ignoreSpaces=False) is False):
                    self.eventName = str(parsedArgs.eventname)
            except TypeError as typeError:
                    self.eventName = ''

            try:
                if (self.utility.stringIsEmpty(parsedArgs.pathformat, ignoreSpaces=False) is False):
                    try:
                        self.pathFormat = self.pathFormatChoices[parsedArgs.pathformat]
                    except KeyError:
                        self.pathFormat = EnumPathFormat.PATHFORMAT_DEFAULT
            except TypeError as typeError:
                self.pathFormat = EnumPathFormat.PATHFORMAT_DEFAULT

            if (parsedArgs.incrementfilenames == True):
                self.filenameIncrement = True
            else:
                self.filenameIncrement = False

            if (parsedArgs.movefiles == True):
                self.moveFiles = True
            else:
                self.moveFiles = False

            # TODO: ADD copy_file update functionality.
            # This should only be implemented when filecontent compare has been added. Or unique file identification in
            # some other way has been added to the program. And the incrementFilename functionality needs to work correctly with
            # this functionality on or off.
            if (parsedArgs.enablecopyupdate == True):
                self.enableCopyFileUpdateOption = True
            else:
                self.enableCopyFileUpdateOption = False

            if (parsedArgs.disableexif == True):
                self.checkExifData = False
            else:
                self.checkExifData = True

            if (parsedArgs.enableosattributes == True):
                self.checkOsStatResult = True
            else:
                self.checkOsStatResult = False

            if (self.sourceFolderArgvSupplied == False):
                self.useDefaultSourceFolder = True
            else:
                self.useDefaultSourceFolder = False

            if  (self.destinationFolderArgvSupplied == False):
                self.useDefaultDestinationFolder = True
            else:
                self.useDefaultDestinationFolder = False

        return parsedArgs

    def setupEnvironment(self, parsedArgs):
        result = True  # Assume success, falsify is an error is found.
        sourceFolderAvailable      = False
        destinationFolderAvailable = False
        tempFolderAvailable        = False

        if os.path.exists(self.baseFolder) is False:  # It should or else sum'in is up.
            result = False
            self.utility.myPrintMessage('setupEnvironment(): Basefolder not available.', paddingType=0)
        else:
            #Generate names for folders used by the algorithm.
            if self.generateNaming(parsedArgs) is False:
                self.utility.systemExit(1, 'Error in generateNaming function. Exit')
            else:
                pass

            # Verification and generation if doNotExist: self.tempFolder etc.
            self.utility.myPrintMessage('Setting up required directories:', paddingType=0)
            self.utility.myPrintMessage(self.sourceFolder, paddingType=1)
            self.utility.myPrintMessage(self.destinationFolder, paddingType=1)

            sourceFolderAvailable = self.fileHandler.createDirectory(self.sourceFolder)
            destinationFolderAvailable = self.fileHandler.createDirectory(self.destinationFolder)

            #self.utility.myPrintMessage(self.tempFolder, paddingType=1)
            # #tempFolderAvailable = self.fileHandler.createDirectory(self.tempFolder)
            #if sourceFolderAvailable == False or destinationFolderAvailable == False or \
            #   tempFolderAvailable == False:

            if (sourceFolderAvailable == False or destinationFolderAvailable == False):
                result = False
            else:
                result = True

        return result

    def generateNaming(self, parsedArgs):
        result = False

        if (self.useDefaultSourceFolder is True):
            self.sourceFolder = self.fileHandler.generatePath(str(self.baseFolder + '/SortTheseFiles'))
        else:
            self.sourceFolder = self.fileHandler.generatePath(str(parsedArgs.inputpath))

        if (self.useDefaultDestinationFolder is True):
            self.destinationFolder = self.fileHandler.generatePath(str(self.baseFolder + '/destination'))
        else:
            self.destinationFolder = self.fileHandler.generatePath(str(parsedArgs.outputpath))

        #self.tempFolder = self.fileHandler.generatePathByDateTime(str(self.baseFolder + '/tmp_'))

        #if self.sourceFolder == '' or self.destinationFolder == '' or self.tempFolder == '':
        if ((self.sourceFolder == '') or (self.destinationFolder == '')):
            result = False
            self.utility.systemExit(1, 'Error in path naming.')
        else:
            result = True

        return result

    def addOptionalEventFolderName(self, basePath, eventName):
        fPath = ''

        try:
            if (utility.stringIsEmpty(eventName) == True):
                return basePath
        except TypeError as typeError:
            return basePath

        fPath = self.fileHandler.generatePath(str(basePath) + ' - ' + eventName)
        return fPath

    def startSortation(self):
        fileInfoObj = None
        fileList = []
        file = ''
        dataSizeInTotal = 0
        dataSizeCurrentProgress = 0
        filesProcessed = 0
        filesCopiedOrMoved = 0
        invalidDateTimeOriginalFound = 0
        validDateTimeOriginalFound = 0
        unhandledFile = 0

        self.validFilesOutputFile = self.fileHandler.generatePath(self.destinationFolder + '\\' + 'validFiles.txt')
        self.invalidFilesOutputFile = self.fileHandler.generatePath(self.destinationFolder + '\\' + 'invalidFiles.txt')
        self.sortingResultFile = self.fileHandler.generatePath(self.destinationFolder + '\\' + 'sortingResult.txt')

        logString = '------------------------------------------------------------------------------\n'
        logString = logString + str('File Sortation - ' + utility.getCurrentTimeAsString() + '\n')
        try:
            utility.logStringToFile(self.validFilesOutputFile, 'a', logString)
        except Exception as e:
            print (str(e))
        try:
            utility.logStringToFile(self.invalidFilesOutputFile, 'a', logString)
        except Exception as e:
            print(str(e))
        try:
            utility.logStringToFile(self.sortingResultFile, 'a', logString)
        except Exception as e:
            print(str(e))

        self.utility.myPrintMessage('Start Sortation function:', paddingType=0)
        fileList = self.fileHandler.retrieveFileList(self.sourceFolder)

        if len(fileList) == 0:
            self.utility.myPrintMessage('No files in the source folder. Done', paddingType=1)
        else:
            #Foreach file - retrieve exifData - DateTimeOriginal.
            self.utility.myPrintMessage('Processing file list:', paddingType=1)
            i = 0
            
            if len(fileList) < 10:
                indicationDelay = 0
            else:
                indicationDelay = 5

            utility.resetIndicationCounter(indicationDelay) #This ensures that the first progress indication is printed (ie: 0%).
            utility.resetNewLineLimitCounter()

            # Show 0 progress.
            utility.showProcessingProgress(EnumProgressIndicator.INDICATOR_ITEM_COUNTER, indicationDelay, len(fileList), i, EnumProgressDataFormat.DATAFORMAT_UNDEFINED, EnumProgressRelativity.INDICATOR_RELATIVE)
            while i < len(fileList):
                fileInfoObj = fileList[i]
                if fileInfoObj.getIsValidFileAdded() is True: #This only confirms that a valid file has been found. Not that is contains valid exif data.
                    file = fileInfoObj.getFileHandle()
                    try:  # Store fileSize etc in FileInfo object.
                        fileInfoObj.setFileStatResultObj(self.fileHandler.getFileDescriptorData(file))
                        dataSizeInTotal += fileInfoObj.getFileSizeInBytes()
                    except Exception as e:
                        print('  Error: ' + str(e))

                    tagValue = self.examineFileForExifData(file)

                    if ((self.timeDateHandler.isExifDateTimeFieldValid(tagValue) is False) and self.checkOsStatResult == True):
                        tagValue = self.examineFileStatResultObj(fileInfoObj)

                    try:
                        if (self.timeDateHandler.isDateTimeFieldValid(tagValue) is True):
                            fileInfoObj.setDateTimeOriginal(tagValue, self.pathFormat)
                            fileInfoObj.setDateTimeFormat(self.timeDateHandler.checkDateTimeField_FormatDate_YYYY_MM_DD__TIME_HH_MM_SS(tagValue))
                        else:
                            pass

                    except Exception as e:
                        print ('Error in setDateTimeOriginal: ' + str(e))
                        print(traceback.print_exc())
                        sys.exit(1) # Exit if the data info isn't handled correctly. This means that the program requires improvement.
                    (filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved) = self.updateProcessingSummary(fileInfoObj, filesProcessed, validDateTimeOriginalFound,invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved)
                i += 1
                utility.showProcessingProgress(EnumProgressIndicator.INDICATOR_ITEM_COUNTER, indicationDelay, len(fileList), i, EnumProgressDataFormat.DATAFORMAT_UNDEFINED, EnumProgressRelativity.INDICATOR_RELATIVE)
                fileInfoObj = None

            #Copy or move files to destinationFolder.
            if (self.moveFiles == False):
                self.utility.myPrintMessage('\nCopying files:', paddingType=1)
            else:
                self.utility.myPrintMessage('\nMoving files:', paddingType=1)

            dataFormat = utility.chooseProgressIndicationDataFormat(dataSizeInTotal)
            self.calculateConversionFactor_Base2(dataFormat)

            i = 0
            utility.resetIndicationCounter(indicationDelay) #This ensures that the first progress indication is printed (ie: 0%).
            utility.resetNewLineLimitCounter()

            # Show 0 progress.
            utility.showProcessingProgress(EnumProgressIndicator.INDICATOR_DATASIZE_COUNTER, indicationDelay, int(dataSizeInTotal/self.conversionFactor), int(dataSizeCurrentProgress/self.conversionFactor), dataFormat, EnumProgressRelativity.INDICATOR_RELATIVE)
            while i < len(fileList):
                fileInfoObj = fileList[i]
                if ((fileInfoObj.getTimeFound() is True) and (fileInfoObj.getFileProcessed() is True)):
                    dstFolder = self.fileHandler.generatePath(str(self.destinationFolder + '\\' + fileInfoObj.getFolderName()))
                    try:
                        if (self.utility.stringIsEmpty(self.eventName) == False):
                            dstFolder = self.addOptionalEventFolderName(dstFolder, self.eventName)
                    except TypeError as typeError:
                        self.utility.systemExit(1, 'Error in eventName variable.')
                    self.fileHandler.createDirectory(dstFolder)

                    if (self.moveFiles == True):
                        if (self.fileHandler.moveFile(fileInfoObj.getFilePathWithFileName(), dstFolder, self.filenameIncrement) == True):
                            filesCopiedOrMoved += 1
                        else:  # Handle failed copy of valid file?
                            pass
                    else:
                        if (self.fileHandler.copyFile(fileInfoObj.getFilePathWithFileName(), dstFolder, self.filenameIncrement, self.enableCopyFileUpdateOption) == True):
                            filesCopiedOrMoved += 1
                        else: # Handle failed copy of valid file?
                           pass
                elif (fileInfoObj.getExifTagError() is True) and (fileInfoObj.getFileProcessed() is True):
                    # Copy "unhandled" files to a specific folder. These files did not provide exif data.
                    dstFolder = self.fileHandler.generatePath(str(self.destinationFolder + '\\' + 'ExifDataNotRetrieved_TheseFilesRequiresManualUserAttention'))
                    self.fileHandler.createDirectory(dstFolder)
                    if (self.moveFiles == True):
                        if (self.fileHandler.moveFile(fileInfoObj.getFilePathWithFileName(), dstFolder, self.filenameIncrement) == True):
                            filesCopiedOrMoved += 1
                        else:  # Handle failed copy of valid file?
                            pass
                    else:
                        if (self.fileHandler.copyFile(fileInfoObj.getFilePathWithFileName(), dstFolder, self.filenameIncrement, self.enableCopyFileUpdateOption) == True):
                            filesCopiedOrMoved += 1
                        else: # Handle failed copy of valid file?
                           pass
                else:
                    pass

                dataSizeCurrentProgress += fileInfoObj.getFileSizeInBytes()
                i += 1
                utility.showProcessingProgress(EnumProgressIndicator.INDICATOR_DATASIZE_COUNTER, indicationDelay, int(dataSizeInTotal/self.conversionFactor), int(dataSizeCurrentProgress/self.conversionFactor), dataFormat, EnumProgressRelativity.INDICATOR_RELATIVE)
                fileInfoObj = None

            self.printProcessingSummary(filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved)
            self.writeProcessingSummaryToFile(filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved)
            self.fileHandler.deleteEmptyFolders(self.sourceFolder)

    # The conversion factors in this function is based on the binary base 2 format (1KB = 1024Bytes). SI uses base 10 format (1KB = 1000B).
    def calculateConversionFactor_Base2(self, dataFormat):
        if dataFormat == EnumProgressDataFormat.DATAFORMAT_UNDEFINED:
            self.conversionFactor = 1
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_BITS:
            self.conversionFactor = (1/8)
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_BYTES:
            self.conversionFactor = 1
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_KILOBYTES: #2^10
            self.conversionFactor = 2**10
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_MEGABYTES: #2^20
            self.conversionFactor = 2**20
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_GIGABYTES: #2^30
            self.conversionFactor = 2**30
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_TERABYTES: #2^40
            self.conversionFactor = 2**40
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_PETABYTES: #2^50
            self.conversionFactor = 2**50
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_EXABYTES: #2^60
            self.conversionFactor = 2**60
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_ZETTABYTES: #2^70
            self.conversionFactor = 2**70
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_YOTTABYTES: #2^80
            self.conversionFactor = 2**80

    # The conversion factors in this function is based on the SI unit base 10 format (1KB = 1000Bytes).
    def calculateConversionFactor_Base10(self, dataFormat):
        if dataFormat == EnumProgressDataFormat.DATAFORMAT_UNDEFINED:
            self.conversionFactor = 1
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_BITS:
            self.conversionFactor = (1/8)
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_BYTES:
            self.conversionFactor = 1
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_KILOBYTES: #1000^1
            self.conversionFactor = 1000**1
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_MEGABYTES: #1000^2
            self.conversionFactor = 1000**2
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_GIGABYTES: #1000^3
            self.conversionFactor = 1000**3
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_TERABYTES: #1000^4
            self.conversionFactor = 1000**4
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_PETABYTES: #1000^5
            self.conversionFactor = 1000**5
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_EXABYTES: #1000^6
            self.conversionFactor = 1000**6
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_ZETTABYTES: #1000^7
            self.conversionFactor = 1000**7
        elif dataFormat == EnumProgressDataFormat.DATAFORMAT_YOTTABYTES: #1000^8
            self.conversionFactor = 1000**8
            
    def updateProcessingSummary(self, fileInfoObj, filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved):
        if (fileInfoObj.getExifTagError() is True):
            invalidDateTimeOriginalFound += 1
        elif (fileInfoObj.getTimeFound() is True):
            validDateTimeOriginalFound += 1
        else:
            unhandledFile += 1

        filesProcessed += 1
        return (filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved)

    def printProcessingSummary(self, filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved):
        summaryString = self.generateSummaryOutput(filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved)
        # Summary
        self.utility.myPrintMessage(summaryString, paddingType=1)

    def writeProcessingSummaryToFile(self, filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved):
        summaryString = self.generateSummaryOutput(filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved)

        # Summary
        utility.logStringToFile(self.sortingResultFile, 'a', summaryString)

    def generateSummaryOutput(self, filesProcessed, validDateTimeOriginalFound, invalidDateTimeOriginalFound, unhandledFile, filesCopiedOrMoved):
        noOfDigits = int(len(str(filesProcessed)))
        if (noOfDigits < 1):
            noOfDigits = 2

        summaryString1 = '\n\nFile sortation summary:'
        summaryString2 = '\n\tTotal number of files processed:   ' + str(filesProcessed).rjust(noOfDigits, ' ')
        summaryString3 = '\n\tFiles sorted succcessfully:        ' + str(filesCopiedOrMoved).rjust(noOfDigits, ' ')
        summaryString4 = '\n\tValid DateTimeOriginal Found:      ' + str(validDateTimeOriginalFound).rjust(noOfDigits, ' ')
        summaryString5 = '\n\tFiles requiring manual sorting:    ' + str(invalidDateTimeOriginalFound).rjust(noOfDigits, ' ')
        summaryString6 = '\n\tUnhandled file. Unexpected error:  ' + str(unhandledFile).rjust(noOfDigits, ' ')
        summaryStringSrc = '\n\tKilde:       ' + str(self.sourceFolder)
        summaryStringDst = '\n\tDestination: ' + str(self.destinationFolder)
        summaryStringEnd = '\n------------------------------------------------------------------------------\n'

        summaryString = str(summaryString1 + summaryString2 + summaryString3 + summaryString4 + summaryString5 + summaryString6 + summaryStringSrc + summaryStringDst + summaryStringEnd)
        return summaryString

    def examineFileForExifData(self, file):
        tagValue = ''
        foundValidExifDateTimeField = False
        tags = ['DateTimeOriginal', 'DateTime', 'DateTimeDigitized']

        if (self.checkExifData == True):
            for item in tags:
                tag = item
                entry = self.getExifTagValue(file,tag)
                tagValue = self.removeTrailingNullEscapeChar(entry)

                if (self.timeDateHandler.isExifDateTimeFieldValid(tagValue) == True):
                    foundValidExifDateTimeField = True
                else: # Continue search for a tag with valid data.
                    foundValidExifDateTimeField = False

                if (foundValidExifDateTimeField == True): #Break outpf loop. We found  valid time with data.
                    break
                else: # Continue search for a tag with valid data.
                    tagValue = ''
                    pass
        else:
            tagValue = ''

        return tagValue

    def getExifTagValue(self, file, tagName):
        exifDictionary = {}
        exifDictionary = self.retrieveExifData(file)
        value = exifDictionary.get(tagName)

        if ((value is None) or (value == '') or (str(value).strip(' ') == '') ):
            value = ''

        return value

    def retrieveExifData(self, file):
        exifDictionary = {}
        fileHandle = None

        try:
            fileHandle = Image.open(file, "r")
            exifInfo = fileHandle._getexif()

            for tag, value in exifInfo.items():
                retrieved = TAGS.get(tag, tag)
                exifDictionary[retrieved] = value

            utility.logStringToFile(self.validFilesOutputFile, 'a', str('FileName: ' + str(file) + '\n'))
        except Exception as e:
            utility.logStringToFile(self.invalidFilesOutputFile, 'a', str('FileName: ' + str(file) + '\n'))

        return exifDictionary

    #This function tries to remove trailing null escape characters from dateTime exif timestamps.
    def removeTrailingNullEscapeChar(self, data):
        value = data
        
        if ( value == '' ):
            return value
        else:
            try:
                value = str(data).strip('\x00')
            except Exception as e:
                print('Error in removeTrailingNullEscapeChar: ' + str(e))
                print(traceback.print_exc())

            #'\0'            (0)                  0b00000000     0x00
            #'0'             (48 decimal)         0b00110000     0x30
            #'9'             (57 decimal)         0b00111001     0x39
            #ord() - Get integer value of the ascii character.
            try:
                lastChar = value[-1:] #Retrieve last character of the tagValue.
                asciiValue = ord(lastChar)
            except Exception as e:
                print('Error in removeTrailingNullEscapeChar: ' + str(e))

            if ( (asciiValue >= 0x30) or (asciiValue <= 0x39) ):
                value = data
            else:
                try:
                    value = str(value).strip('\0x00')
                except Exception as e:
                    print('Error in removeTrailingNullEscapeChar: ' + str(e))
                    print(traceback.print_exc())

        return value

    def examineFileStatResultObj(self, fileInfoObj):
        dateTimeString = ''
        foundValidDateTimeField = False

        if (self.checkOsStatResult == True):
            #Returns integer-based timestamp
            mtime = fileInfoObj.getFileModificationTime()
            ctime = fileInfoObj.getFileCreationTime()

            #Choose modification time over creation time.
            #Exif dateTime format is: YYYY:MM:DD HH:MM:SS 24-HOUR, EXIF SPECIFICATION 2.2
            if (mtime != 0):
                dateTime = datetime.datetime.fromtimestamp(mtime)
                dateTimeString = str(dateTime.year).rjust(4, '0') + ':' + str(dateTime.month).rjust(2, '0') + ':' + str(dateTime.day).rjust(2, '0') + ' ' + str(dateTime.hour).rjust(2, '0')  + ':' + str(dateTime.minute).rjust(2, '0') + ':' + str(dateTime.second).rjust(2, '0')
            elif (ctime != 0):
                dateTime = datetime.datetime.fromtimestamp(ctime)
                dateTimeString = str(dateTime.year).rjust(4, '0') + ':' + str(dateTime.month).rjust(2, '0') + ':' + str(dateTime.day).rjust(2, '0') + ' ' + str(dateTime.hour).rjust(2, '0') + ':' + str(dateTime.minute).rjust(2, '0') + ':' + str(dateTime.second).rjust(2, '0')
            else:
                dateTimeString = ''

            if (self.timeDateHandler.isFileStatResultDataTimeFieldValid(dateTimeString) == True):
                foundValidDateTimeField = True
            else:
                foundValidDateTimeField = False

            if (foundValidDateTimeField == True):  # Break outpf loop. We found  valid time with data.
                pass
            else:  # Continue search for a tag with valid data.
                dateTimeString = ''
        else:
            dateTimeString = ''

        return dateTimeString

    def assertTests(self):
        print ('Not implemented. Look at FileAndPathHandler.assertTests() for inspiration')
        return True

if __name__ == '__main__':
    try:
        utility = CoolUtility()
        sortationHandler = SortationHandler(sys.argv[1:])
        utility.systemExit(0, "Bye")
    except Exception as e:
        utility.myPrintMessage(str(traceback.print_exc()), paddingType=1)
        utility.systemExit(1, '    - error: ' + str(e))

    # Unit testing
    #fileHandler = ownImports.file_path.FileAndPathHandler()
    #fileInfo = ownImports.file_path.FileInfo()
    #sortationHandler = SortationHandler(sys.argv[1:])
    #utility.assertTests()
    #fileHandler.assertTests() # Asserts - unit testing.
    #fileInfo.assertTests()  # Asserts - unit testing.
    #sortationHandler.assertTests()