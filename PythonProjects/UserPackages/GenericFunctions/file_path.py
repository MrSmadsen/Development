import os
import sys
import traceback
import distutils.file_util
import datetime
import enum
import GenericFunctions.time

from GenericFunctions.time import TimeDateHandler

#General description
#Developed and tested on Python 3.6.1

from GenericFunctions.utility import CoolUtility

class EnumPathFormat(enum.IntEnum):
    PATHFORMAT_DEFAULT = 1
    PATHFORMAT_SUBYEAR = 2
    PATHFORMAT_SUBYEAR2 = 3
    PATHFORMAT_SUBYEARMONTH = 4

class FileInfo:
    # This is a class variable shared by ALL instances (Similar to a static Java-variable?)
    moduleName = "FileInfo Class"

    def __init__(self, fileObject, fileName, filePath):
        self.name = "FileInfo"
        self.utility = CoolUtility()
        self.timeDateHandler = TimeDateHandler()

        if os.path.isfile(fileObject):
            self.fileObject = fileObject
            self.fileName = fileName
            self.filePath = filePath
            self.validFileAdded = True
        else:
            self.fileObject = ''
            self.fileName = ''
            self.filePath = ''
            self.validFileAdded = False

        self.fileStatObj = None
        self.generatedFolderName = ''
        self.dateTimeOriginal = ''
        self.fileProcessed = False
        self.exifTagError = False
        self.timeFound = False
        self.defaultDate = '1998 11. september'
        self.defaultDateChoices = {1:'1000 - januar 01', 2:'/1000/januar 01', 3:'/1000/11. januar', 4:'/1000/januar/11'}
        self.months = ['januar','februar','marts','april','maj','juni','juli','august','september','oktober','november','december']
        self.extractedYear = ''
        self.extractedMonth = ''
        self.extractedDay = ''
        self.datetimeFormat = GenericFunctions.time.EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED

    def getFileName(self):
        return self.fileName

    def getFilePathWithFileName(self):
        return self.fileObject

    def getFilePath(self):
        return self.filePath

    def getFileHandle(self):
        return self.fileObject

    def getDateTimeOriginal_Year(self):
        return self.extractedYear

    def getDateTimeOriginal_Month(self):
        return self.extractedMonth

    def getDateTimeOriginal_Day(self):
        return self.extractedDay

    def getDateTimeFormat(self):
        return self.datetimeFormat

    def setDateTimeFormat(self, format):
        self.datetimeFormat = format

    def setFileStatResultObj(self, fileStatObj):
        if (fileStatObj is None):
            return False
        else:
            self.fileStatObj = fileStatObj
            return True

    def getFileSizeInBytes(self):
        if (self.fileStatObj is None):
            return 0
        else:
            return self.fileStatObj.st_size

    def getFileModificationTime(self):
        if (self.fileStatObj is None):
            return 0
        else:
            mtime = self.fileStatObj.st_mtime
            return mtime

    def getFileCreationTime(self):
        if (self.fileStatObj is None):
            return 0
        else:
            ctime = self.fileStatObj.st_ctime
            return ctime

    def setDateTimeOriginal(self, dateTimeOriginal, pathFormat):
        try:
            dateTimeForPath = self.defaultDateChoices[pathFormat]
        except KeyError:
            dateTimeForPath = self.defaultDate
            raise KeyError('Error in pathFormat.')

        self.dateTimeOriginal = dateTimeOriginal

        try:
            if (self.utility.stringIsEmpty(dateTimeOriginal) == True):
                self.exifTagError = True
                self.timeFound = False
                self.generatedFolderName = dateTimeForPath
            else:
                if (self.timeDateHandler.isDateTimeFieldValid(dateTimeOriginal) == True):
                    self.generatedFolderName = self.extractDate(dateTimeOriginal, pathFormat)
                    self.exifTagError = False
                    self.timeFound = True
                else:
                    self.exifTagError = True
                    self.timeFound = False
                    self.generatedFolderName = dateTimeForPath

            self.fileProcessed = True
        except TypeError as typeError:
            raise TypeError('Error generating the foldername and setting the DateTime value.')

    def extractDate(self, value, pathFormat=EnumPathFormat.PATHFORMAT_DEFAULT):
        dateToken = yearIndex = monthIndex = dayIndex = ''
        tokens = None

        tokens = value.split(' ') # Result: tokens[0]: Date, tokens[1]: time.
        if (len(tokens) == 2):
            value = tokens[0]
            tokens = value.split(':') # Result: tokens[0]: Year, tokens[1]: Month, tokens[2]: day.
            if (len(tokens) == 3):
                pass
            else:
                dateToken = self.defaultDate
                return dateToken
        else:
            dateToken = self.defaultDate
            return dateToken

        #Validate tokens:  Year                 month                     Day.
        if (len(tokens[0]) == 4) and (len(tokens[1]) == 2) and (len(tokens[2]) == 2):
            # Exif tag DateTimeOriginal (exif tag 36867 (9003.H))
            # Format: YYYY:MM:DD HH:MM:SS 24-HOUR, EXIF SPECIFICATION 2.2
            self.extractedYear  = str(tokens[0])
            monthIndex = int(tokens[1])
            if (monthIndex > 0) and (monthIndex < 13):
                monthIndex = monthIndex - 1 # list is zero-based
                self.extractedMonth = str(self.months[monthIndex])
            else: # Invalid month index
                monthIndex = 0 # januar
                self.extractedMonth = str(self.months[monthIndex])

            self.extractedDay = str(int(tokens[2]))

            if (pathFormat == EnumPathFormat.PATHFORMAT_SUBYEAR):
                dateToken = str(str('/') + self.extractedYear + str('/') + self.extractedMonth + str(' ') + self.extractedDay)  #+ str(' ')
            elif (pathFormat == EnumPathFormat.PATHFORMAT_SUBYEAR2):
                dateToken = str(str('/') + self.extractedYear + str('/') + self.extractedDay + str('. ') + self.extractedMonth)
            elif (pathFormat == EnumPathFormat.PATHFORMAT_SUBYEARMONTH):
                dateToken = str(str('/') + self.extractedYear + str('/') + self.extractedMonth + str('/') + self.extractedDay)
            else:
                dateToken = str(self.extractedYear + str(' - ') + self.extractedMonth + str(' ') + self.extractedDay)
        else:
            dateToken = self.defaultDate

        return dateToken

    def getFolderName(self):
        return self.generatedFolderName

    def getDateTimeOriginal(self):
        return self.dateTimeOriginal

    def getFileProcessed(self):
        return self.fileProcessed

    def getExifTagError(self):
        return self.exifTagError

    def getTimeFound(self):
        return self.timeFound

    def getIsValidFileAdded(self):
        return self.validFileAdded

    def assertTests(self):
        print ('Not implemented. Look at FileAndPathHandler.assertTests() for inspiration')
        return True

class FileAndPathHandler:
    moduleName = "FileAndPathHandler Class"  # This is a class variable shared by ALL instances.

    def __init__(self):
        self.name = "FileAndPathHandler"
        self.utility = CoolUtility()

        self.encoding = self.getFileSystemEncoding()

    # Returns None if default encoding is used or a string encpasulating the encoding used.
    def getFileSystemEncoding(self):
        encoding = None
        encoding = sys.getfilesystemencoding()
        return encoding

    def generateUniqueFilePath(self, filePath):
        fPath = filePath
        # This will loop for as long as the check confirms a filename clash in the destination folder.
        while ((os.path.isfile(fPath) == True)):
            fileName = str(os.path.basename(fPath))
            try:
                fileName = self.incrementFileName(fileName)
            except Exception as e:
                print (str(e))
                sys.exit(1)

            fPath = self.generatePath(str(os.path.dirname(filePath)) + '\\' + fileName)

        return fPath

    #Tested successfully with following data:
    #fileHandler = GenericFunctions.file_path.FileAndPathHandler()
    #fileHandler.incrementFileName('test.testname.something.txt')
    #fileHandler.incrementFileName('test.testname.something1.txt')
    #fileHandler.incrementFileName('test.testname.something13432526.txt')
    #fileHandler.incrementFileName('test.testname.something__NytFilNavn1.txt')
    #fileHandler.incrementFileName('test.testname.something__NytFilNavn1234235324.txt')
    #fileHandler.incrementFileName('test.testname.something__NytFilNavn.txt')
    #fileHandler.incrementFileName(10)

    def incrementFileName(self, fileName):
        suffixIndex = 0
        prefixLength = 0
        defaultIncSeperator = '__NytFilNavn'
        defaultIncNumber = 1
        prefix = ''
        suffix = ''
        lastChars = ''
        lastCharIndex = numericCharIndex = 0

        # Verify parameter is a string.
        if (isinstance(fileName, str) == True):
            # Extract prefix and suffix.
            tokens = fileName.split('.')

            if (len(tokens) == 1):
                raise TypeError('incrementFilename: fileName not accepted by the function. name.extension expected.')

            suffixIndex = (len(tokens) - 1)
            suffix = str(tokens.pop(suffixIndex))

            #                              (suffix + seperator)
            prefixLength = len(fileName) - (len(suffix) + 1)
            prefix = str(fileName[:prefixLength])

            if (prefix.isnumeric() == True):
                prefix = str(prefix + (str(defaultIncSeperator) + str(defaultIncNumber)))
                fileName = prefix + '.' + suffix
                return fileName

            # Figure out what the last item of the prefix consists of.
            numericCharIndex = lastCharIndex = len(prefix) - 1
            lastChars = str(prefix[lastCharIndex:])

            if (lastChars.isnumeric() == False):
                if (prefix.endswith(defaultIncSeperator) == True):  # defaultIncSeperator but no number: Add number.
                    prefix = str(prefix + str(defaultIncNumber))
                else:  # Add default inc data.
                    prefix = str(prefix + (str(defaultIncSeperator) + str(defaultIncNumber)))
                fileName = prefix + '.' + suffix
            else:  # last prefix character is a numeric value.
                # Extract ending numeric part.
                while (lastChars.isnumeric()):
                    numericCharIndex = numericCharIndex - 1
                    lastChars = str(prefix[numericCharIndex:])

                numericChars = str(prefix[(numericCharIndex + 1):])
                preNumericChars = str(prefix[:(numericCharIndex + 1)])

                if (preNumericChars.endswith(defaultIncSeperator) == True):  # Already incremented: Increment number only.
                    incNumber = (int(numericChars) + 1)
                    prefix = preNumericChars + str(incNumber)
                else:  # Add default inc data.
                    prefix = str(prefix + (str(defaultIncSeperator) + str(defaultIncNumber)))

                fileName = prefix + '.' + suffix
        else:  # If nothing to do. Return original parameter.
            raise TypeError('incrementFilename: fileName is not a valid string.')

        return fileName

#Handles destination paths without filename. Should also handle destination paths with file names.
    def copyFile(self, sourceFile, destPath, fileNameIncrement=True, enableCopyFileUpdateOption=False):
        result = False
        result = self._copyOrMoveFile(sourceFile, destPath, fileNameIncrement, enableCopyFileUpdateOption, keepItem=True)
        return result

        # Handles destination paths without filename. Should also handle destination paths with file names.
    def moveFile(self, sourceFile, destPath, fileNameIncrement=True):
        result = False
        result = self._copyOrMoveFile(sourceFile, destPath, fileNameIncrement, enableCopyFileUpdateOption=False, keepItem=False)
        return result

    # Leading underscore defines this as a "weak private" function. It won't show up in import statements but is directly callable.
    def _copyOrMoveFile(self, sourceFile, destPath, fileNameIncrement=True, enableCopyFileUpdateOption=False, keepItem=True):
        result = False
        applyNewDestinationName = False
        destPathWithFileName = ''
        newFilePath = ''
        functionName = ''

        if (keepItem == True):
            functionName = 'copyFile'
        else:
            functionName = 'moveFile'


        if ((os.path.isfile(sourceFile) == False)):
            self.utility.myPrintMessage(functionName + ': No source file found. Aborting.', paddingType=1)
            return False

        if (os.path.exists(destPath) == False):
            self.utility.myPrintMessage(functionName + ': Destination path not found. Aborting.', paddingType=1)
            return False

        fileName = str(os.path.basename(sourceFile))
        destPathWithFileName = self.generatePath((destPath + '\\' + fileName))

        if (fileNameIncrement == False):
            if (os.path.isfile(destPath) == True):
                self.utility.myPrintMessage(functionName + ': File already exists. Avoid overwriting file. Aborting.', paddingType=1)
                return False
            elif (os.path.isfile(destPathWithFileName) == True):
                self.utility.myPrintMessage(functionName + ': File already exists. Avoid overwriting file. Aborting.', paddingType=1)
                return False
            else:  # No name clashes. Try to copy.
                pass

                # Not sure this should be consider a fault or just silly file naming?
                # if (os.path.basename(sourceFile) == os.path.basename(destPath)):
                #    self.utility.myPrintMessage(functionName + ': Destination has same name as source file. Rename destination or enable filename increment. Aborting.',paddingType=1)
                #    return False
        else:
            if (os.path.isfile(destPath) == True):
                newFilePath = self.generateUniqueFilePath(destPath)
                if (newFilePath == destPath):
                    return False
                else:
                    applyNewDestinationName = True
            elif (os.path.isfile(destPathWithFileName) == True):
                newFilePath = self.generateUniqueFilePath(destPathWithFileName)
                if (newFilePath == destPathWithFileName):
                    return False
                else:
                    applyNewDestinationName = True
            else:  # No name clashes. Try to copy.
                pass

            if (applyNewDestinationName == True):
                destPath = newFilePath
            else:
                pass

        try:
            if (enableCopyFileUpdateOption == True):
                self.utility.myPrintMessage('\nUpdate functionality not implemenmted yet.. Ignoring.', paddingType=1)
            # TODO:enableCopyFileUpdateOption - Add variable to parameter list including preserver option etc.
            if (keepItem == True): # parameters: src, dst, preserveMode, preserveTime, update, link, verbose, dry_run
                distutils.file_util.copy_file(sourceFile, destPath, True, True)
            else: # parameters: src, dst, verbose, dry_run
                distutils.file_util.move_file(sourceFile, destPath)
            result = True
            # self.utility.myPrintMessage('\nCopy operation OK - File: ' + sourceFile, paddingType=1)
        except Exception as removalException:
            print('    - error: ' + str(removalException))
            print(traceback.print_exc())
            result = False

        return result

    def copyDirectory(self):
        result = False
        self.utility.myPrintMessage('FileAndPathHandler->copyDirectory: This function has not been implemented yet!',
                                    paddingType=1)
        return result

    def moveDirectory(self):
        result = False
        self.utility.myPrintMessage('FileAndPathHandler->moveDirectory: This function has not been implemented yet!', paddingType=1)
        return result

    def fileVerification(self, sourceFile, filePath, checksum=0):
        self.utility.myPrintMessage('BackupHandler->fileVerification: This function has not been implemented yet!', paddingType=0)
        result = False

        self.utility.myPrintMessage('\nFileVerification', paddingType=0)
        self.utility.myPrintMessage('\nFileVerification operation - File: ' + sourceFile, paddingType=1)
        self.utility.myPrintMessage('\nFileVerification operation - Source: ' + filePath, paddingType=1)

        if os.path.exists(filePath):
            if os.path.isfile(sourceFile) is True:
                #Perform some sort of checksum verification here.
                result = True
            else:
                result = False

        return result

    def getFileDescriptorData(self, itemFile):
        fileStatObj = None
        # https://docs.python.org/3.6/library/os.html#os.stat_result
        try:
            fileStatObj = os.stat(itemFile)
        except Exception as e:
            print ('- Error: ' + str(e))

        return fileStatObj

    def encodeString(self, stringToEncode, useEncoding=''):
        strResult = ''
        sysEncoding = ''

        if (isinstance(stringToEncode, str)):
            if (isinstance(useEncoding, str)):
                if (useEncoding == 'utf-8'):
                    strResult = stringToEncode.encode('utf-8')
                elif (useEncoding == 'mbcs'):
                    strResult = stringToEncode.encode('mbcs')
                elif (useEncoding == ''):
                    sysEncoding = sys.getfilesystemencoding()
                    strResult = stringToEncode.encode(sysEncoding)
                else:
                    print ('encodeString: unexected error.')
        else:
            print('encodeString: No valid string supplied..')

        return strResult

    def decodeString(self, stringToDecode, useEncoding=''):
        strResult = ''
        sysEncoding = ''

        if (isinstance(stringToDecode, str)):
            if (isinstance(useEncoding, str)):
                if (useEncoding == 'utf-8'):
                    strResult = stringToDecode.decode('utf-8')
                elif (useEncoding == 'mbcs'):
                    strResult = stringToDecode.decode('mbcs')
                elif (useEncoding == ''):
                    sysEncoding = sys.getfilesystemencoding()
                    strResult = stringToDecode.decode(sysEncoding)
                else:
                    print('decodeString: unexected error.')
        else:
            print('decodeString: No valid string supplied..')

        return strResult

    def setFileSystemEncoding(self, useLegacyEncoding=False):
        sysEncoding = sys.getfilesystemencoding()

        if (useLegacyEncoding == True):
            print ('Current encoding: ' + str(sysEncoding))
            sys._enablelegacywindowsfsencoding()
            print('Current encoding: ' + str(sys.getfilesystemencoding()))
        else:
            print ('setFileSystemEncoding : Not implenented for arg->True')

    def retrieveFileList(self, path):
        fileList = []
        try:
            if os.path.exists(path):
                for topDir, folders, files in os.walk(top=path, followlinks=False, topdown=False):
                    for item in files:
                        itemFile = os.path.normpath(os.path.join(topDir, item))
                        if os.path.isfile(itemFile) is True:
                            fileList.append(FileInfo(itemFile, item, topDir))
                        else:
                            pass
                            # To delete sub folders in the temp folder use a similar approach but iterate on folders list.
                            # for items in folders'ish.
            else:
                self.utility.myPrintMessage('Directory error: current directory location is: ', paddingType=1)
                self.utility.myPrintMessage(path, paddingType=1)
                self.utility.myPrintMessage('Directory error: location should be: ', paddingType=1)
                self.utility.myPrintMessage(path, paddingType=1)
        except Exception as removalException:
            print ('    - error: ' + str(removalException))
            print (traceback.print_exc())
            fileList = []
            return fileList

        return fileList

    def generatePathByDateTime(self, pathData):
        path = ''

        try:
            dateTime = datetime.datetime.now()
            dateField = str(dateTime.year) + '-' + str(dateTime.month) + '-' + str(dateTime.day)
            timeField = str(dateTime.hour) + '.' + str(dateTime.minute)
            dateTimeField = dateField + '-' + timeField

            path = os.path.normpath(pathData + dateTimeField)
        except Exception as e:
            print('    - error: ' + str(e))
            print(traceback.print_exc())
            path = ''

        return path

    def generatePath(self, pathData):
        path = ''

        try:
            path = os.path.normpath(pathData)
        except Exception as e:
            print('    - error: ' + str(e))
            print(traceback.print_exc())
            path = ''

        return path

    # Assuming permissions is rwx for user and readable for group, admin/root.
    def createDirectory(self, pathData, mode=0o755):
        result = False
        try:
            if os.path.exists(pathData) is True:
                #self.utility.myPrintMessage('Directory: ' + pathData + ' already available.', paddingType=1)
                result = True
            else:
                os.makedirs(pathData, mode)
                #os.chmod(pathData, os.stat.S_IWRITE) Does not work. No attribute IWRITE
                if os.path.exists(pathData) is True:
                    result = True
                    #self.utility.myPrintMessage('Directory: ' + pathData + ' created.', paddingType=1)
                else:
                    result = False
                    self.utility.myPrintMessage('Directory: ' + pathData + ' failed.', paddingType=1)
        except Exception as e:
            print('    - error: ' + str(e))
            print(traceback.print_exc())
            result = False

        return result

    def verifyPath(self, path):
        result = False

        if os.path.exists(path) is True:
            result = True
        else:
            pass

        return result

    def verifyFile(self, file):
        result = False
        if os.path.isfile(file) is True:
            result = True
        else:
            pass

        return result

    def deleteEmptyFolders(self, path, deletePathRootFolder=False):
        self.utility.myPrintMessage('Folder-cleanup:', paddingType=0)
        
        if (self.verifyPath(path) is True):
            try:
                for topDir, folders, files in os.walk(top=path, followlinks=False, topdown=False):
                    if ((len(files) == 0) and len(folders) == 0):
                        if (deletePathRootFolder is False):
                            if (topDir == path):
                                pass
                            else:
                                os.rmdir(topDir)
                        else:
                            os.rmdir(topDir)
            except Exception as removalException:
                print('    - error: ' + str(removalException))
                print(traceback.print_exc())
        else:
            self.utility.myPrintMessage('Directory error: The supplied path is not available.', paddingType=1)
            self.utility.myPrintMessage('Path: ' + os.path.normpath(path), paddingType=1)

    # These asserts will be ignored during compilation if optimizations are used and debug info is removed.
    def assertTests(self):
        assert (self.incrementFileName('test.testname.something.txt') == 'test.testname.something__NytFilNavn1.txt')
        assert (self.incrementFileName('test.testname.something1.txt') == 'test.testname.something1__NytFilNavn1.txt')
        assert (self.incrementFileName('test.testname.something13432526.txt') == 'test.testname.something13432526__NytFilNavn1.txt')
        assert (self.incrementFileName('test.testname.something__NytFilNavn1.txt') == 'test.testname.something__NytFilNavn2.txt')
        assert (self.incrementFileName('test.testname.something__NytFilNavn1234235324.txt') == 'test.testname.something__NytFilNavn1234235325.txt')
        assert (self.incrementFileName('test.testname.something__NytFilNavn.txt') == 'test.testname.something__NytFilNavn1.txt')
        assert (self.incrementFileName(10) == 10)
