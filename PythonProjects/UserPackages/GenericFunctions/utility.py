import os
import sys
import datetime
import traceback
import enum

class EnumDemo(enum.IntEnum):
    ENUM1 = 0
    ENUM2 = 1

class EnumProgressRelativity(enum.IntEnum):
    INDICATOR_ABSOLUTE = 0
    INDICATOR_RELATIVE = 1

class EnumProgressIndicator(enum.IntEnum):
    INDICATOR_DOT = 0
    INDICATOR_HYPHEN = 1
    INDICATOR_ITEM_COUNTER = 3
    INDICATOR_DATASIZE_COUNTER = 4

#The number index is the number of bytes in the datatype except the bits and the bytes entries.
# This might change to regular indexes if it doesn't make sence in calculations. This should have an assert test!
class EnumProgressDataFormat(enum.IntEnum):
    DATAFORMAT_UNDEFINED    = 0
    DATAFORMAT_BITS         = 1
    DATAFORMAT_BYTES        = (8*DATAFORMAT_BITS)
    DATAFORMAT_KILOBYTES    = (1024*DATAFORMAT_BYTES)
    DATAFORMAT_MEGABYTES    = (1024*DATAFORMAT_KILOBYTES)
    DATAFORMAT_GIGABYTES    = (1024*DATAFORMAT_MEGABYTES)
    DATAFORMAT_TERABYTES    = (1024*DATAFORMAT_GIGABYTES)
    DATAFORMAT_PETABYTES    = (1024*DATAFORMAT_TERABYTES)
    DATAFORMAT_EXABYTES     = (1024*DATAFORMAT_PETABYTES)
    DATAFORMAT_ZETTABYTES   = (1024*DATAFORMAT_EXABYTES)
    DATAFORMAT_YOTTABYTES   = (1024*DATAFORMAT_ZETTABYTES)

sizeDictionaryShort = { EnumProgressDataFormat.DATAFORMAT_UNDEFINED:  ' ? | ',
                        EnumProgressDataFormat.DATAFORMAT_BITS:       ' b. | ',
                        EnumProgressDataFormat.DATAFORMAT_BYTES:      ' B. | ',
                        EnumProgressDataFormat.DATAFORMAT_KILOBYTES:  ' KB. | ',
                        EnumProgressDataFormat.DATAFORMAT_MEGABYTES:  ' MB. | ',
                        EnumProgressDataFormat.DATAFORMAT_GIGABYTES:  ' GB. | ',
                        EnumProgressDataFormat.DATAFORMAT_TERABYTES:  ' TB. | ',
                        EnumProgressDataFormat.DATAFORMAT_PETABYTES:  ' PB. | ',
                        EnumProgressDataFormat.DATAFORMAT_EXABYTES:   ' EB. | ',
                        EnumProgressDataFormat.DATAFORMAT_ZETTABYTES: ' ZB. | ',
                        EnumProgressDataFormat.DATAFORMAT_YOTTABYTES: ' YB. | '
                     }

sizeDictionaryLong = {  EnumProgressDataFormat.DATAFORMAT_UNDEFINED:  ' ? | ',
                        EnumProgressDataFormat.DATAFORMAT_BITS:       ' bits. | ',
                        EnumProgressDataFormat.DATAFORMAT_BYTES:      ' bytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_KILOBYTES:  ' kilobytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_MEGABYTES:  ' megabytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_GIGABYTES:  ' gigabytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_TERABYTES:  ' terabytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_PETABYTES:  ' petabytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_EXABYTES:   ' exabytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_ZETTABYTES: ' zettabytes. | ',
                        EnumProgressDataFormat.DATAFORMAT_YOTTABYTES: ' yottabytes. | '
                     }

class CoolUtility:
    moduleName = "CoolUtility Class"  # This is a class variable shared by ALL instances

    def __init__(self):
        # EnumDemo.ENUM1 # Just to demonstrate how to imitate enums.
        self.name = "CoolUtility"
        self.indicationCounter = 0
        self.dataFormat = EnumProgressDataFormat.DATAFORMAT_BYTES #Default format because the sorting function retrieves the filesizes in bytes.

    def getCurrentTimeAsString(self):
        dateTime = datetime.datetime.now()
        dateField = str(dateTime.year) + '-' + str(dateTime.month).rjust(2, '0') + '-' + str(dateTime.day).rjust(2, '0')
        timeField = str(dateTime.hour) + '.' + str(dateTime.minute).rjust(2, '0')
        dateTimeField = dateField + '-' + timeField
        return dateTimeField

    def stringIsEmpty(self, myString, ignoreSpaces=False):
        result = False

        if (isinstance(myString, str) == False): # If parameter isn't a string. Return False.
            raise TypeError
        else:
            if (ignoreSpaces == True):
                myString = myString.strip(' ') # str.strip() removes spaces (whitespace)
            else:
                pass

            if (len(myString) == 0):
                result = True
            else:
                result = False

        return result

    def resetIndicationCounter(self, value=0):
        self.indicationCounter = value

    def resetNewLineLimitCounter(self):
        self.newLineLimitCounter = 0

    def showProcessingProgress(self, progressIndicator, indicationDelay = 0, dataSizeInTotal = 0, dataSizeCurrentProgress = 0, dataFormat=EnumProgressDataFormat.DATAFORMAT_BYTES, dataRelativity=EnumProgressRelativity.INDICATOR_ABSOLUTE):
        if dataSizeCurrentProgress == 0: #Ensure the zero-case progress is printed.
            pass
        elif (indicationDelay > 0):
            if (self.indicationCounter == indicationDelay): # DelayLimit reached: Reset the counter and fall through to the self.printProgressIndicator function call below.
                self.resetIndicationCounter()
            else: # If delay is set and the counter hasn't reached the delayLimit we will end in this else.
                self.indicationCounter += 1
                return
        self.printProgressIndicator(progressIndicator, dataSizeInTotal, dataSizeCurrentProgress, dataFormat, dataRelativity)

    def printProgressIndicator(self, progressIndicator, dataSizeInTotal = 0, dataSizeCurrentProgress = 0, dataFormat=EnumProgressDataFormat.DATAFORMAT_BYTES, dataRelativity=EnumProgressRelativity.INDICATOR_ABSOLUTE):
        # end: print end char. Empty string removes auto new line.
        # Flush ensures print to be performed when expected.

        noOfDigits = int(len(str(dataSizeInTotal)))
        if (noOfDigits < 1):
            noOfDigits = 2

        try:
            if (progressIndicator == EnumProgressIndicator.INDICATOR_DOT):
                print('.', end="", flush=True)
                #self.newLineLimitCounter - Add this to limit sideways indication
            elif (progressIndicator == EnumProgressIndicator.INDICATOR_HYPHEN):
                print('-', end="", flush=True)
            elif (progressIndicator == EnumProgressIndicator.INDICATOR_ITEM_COUNTER):
                percentage = self.calculatePercentage(dataSizeCurrentProgress, dataSizeInTotal)
                if (dataRelativity == EnumProgressRelativity.INDICATOR_ABSOLUTE):
                    print((str(dataSizeCurrentProgress).rjust(noOfDigits, '0') + ' of ' + str(dataSizeInTotal) + ' files. | '),end="", flush=True)
                elif (dataRelativity == EnumProgressRelativity.INDICATOR_RELATIVE):
                    print(str(percentage).rjust(3, ' ') + '% done | ', end="",flush=True)
                else:
                    utility.systemExit(0, "ERROR IN EnumProgressRelativity. Exit")

                if (((percentage % 10) == 0) and percentage != 0):
                    print('\n', end="", flush=True)        
            elif (progressIndicator == EnumProgressIndicator.INDICATOR_DATASIZE_COUNTER):
                percentage = self.calculatePercentage(dataSizeCurrentProgress, dataSizeInTotal)
                if (dataRelativity == EnumProgressRelativity.INDICATOR_ABSOLUTE):
                    print((str(dataSizeInTotal) + '/' + str(dataSizeCurrentProgress).rjust(noOfDigits, '0') + sizeDictionaryLong[dataFormat]),end="", flush=True)
                elif (dataRelativity == EnumProgressRelativity.INDICATOR_RELATIVE):
                    print(str(percentage).rjust(3, ' ') + '% done | ', end="",flush=True)
                else:
                    utility.systemExit(0, "ERROR IN EnumProgressRelativity. Exit")

                if (((percentage % 10) == 0) and percentage != 0):
                    print('\n', end="", flush=True)   
            elif (isinstance(progressIndicator, str) and len(progressIndicator) == 1): # Why did I add this code - Custom indicator ?
                print('isinstance section - aprox line 140 utility.py')
                print(progressIndicator, end="", flush=True)
            else:
                raise TypeError('printProgressIndicator only supports 1 character symbols or types specified in utility.EnumProgressIndicator')
        except TypeError as e:
            self.myPrintMessage('- error: ' + str(e), paddingType=1)
    
    def calculatePercentage(self, dataSizeCurrentProgress = 0, dataSizeInTotal = 0):
        percentage = 0
        if (dataSizeInTotal > 0):
            percentage = int(((dataSizeCurrentProgress*100)/dataSizeInTotal))
        else:
            print('DivisionByZeroError - Please provide correct data to the function.')
        return percentage

    def chooseProgressIndicationDataFormat(self, dataSizeInBytes = 0):
        self.dataFormat = EnumProgressDataFormat.DATAFORMAT_BYTES
        dataSizeInBits = 8 * dataSizeInBytes

        if dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_BYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_BITS
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_KILOBYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_BYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_MEGABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_KILOBYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_GIGABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_MEGABYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_TERABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_GIGABYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_PETABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_TERABYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_EXABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_PETABYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_ZETTABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_EXABYTES
        elif dataSizeInBits < EnumProgressDataFormat.DATAFORMAT_YOTTABYTES:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_ZETTABYTES
        else:
            self.dataFormat = EnumProgressDataFormat.DATAFORMAT_YOTTABYTES
        return self.dataFormat
            
    #Add assertion to this method and move it to some python unit-test file.
    def testStringIsEmpty(self):
        try:
            print(self.stringIsEmpty('', False))
            print(self.stringIsEmpty('              ', False))
            print(self.stringIsEmpty('text', False))
            print(self.stringIsEmpty("", False))
            print(self.stringIsEmpty("        ", False))
            print(self.stringIsEmpty("text", False))

            print(self.stringIsEmpty('', True))
            print(self.stringIsEmpty('                 ', True))
            print(self.stringIsEmpty('text', True))
            print(self.stringIsEmpty("", True))
            print(self.stringIsEmpty("               ", True))
            print(self.stringIsEmpty("text", True))
            print (self.stringIsEmpty(None, True)) #This will fail since strip() does not handle None.
        except TypeError as typeError:
            self.myPrintMessage('Default exception handler.', 0)

    def logStringToFile(self, filePath, mode='a', strToLog=''):
        result = False
        file = None

        if ((mode == 'a') or (mode == 'a+') or (mode == 'w')):
            if (os.path.exists(os.path.dirname(filePath)) is True):
                if ((os.path.isfile(filePath) is True) and (mode == 'w')):
                    file = None
                    result = False
                    raise FileExistsError
                elif ((mode == 'a') or (mode == 'a+') or (mode == 'w')):
                        pass
                else:
                    file = None
                    result = False
                    raise ValueError('Unsupported mode detected.')

                try:
                    file = open(filePath, mode)
                except Exception as e:
                    file = None
                    result = False
                    raise IOError(e)

                if ((file.writable() == True) and (self.stringIsEmpty(strToLog) == False)):
                    result = file.write(strToLog)
                    if (result == 0):
                        file = None
                        result = False
                        raise OSError(str(result) + 'bytes written to file.')
                else:
                    if (file.closed == False):
                        file.close()
                    file = None
                    result = False
                    raise OSError('Error writing to file.')

                result = True
                if (file.closed == False):
                    file.close()
            else:
                file = None
                result = False
                raise IsADirectoryError
        else:
            file = None
            result = False
            raise ValueError('Unsupported mode detected.')

        return result

    def myPrintMessage(self, message, paddingType=0):
        if paddingType == 1:  # "Submessage 1"
            padding = '    '
        elif paddingType == 2:  # "Submessage 2"
            padding = '       '
        else:  # "Headline"
            padding = ''

        print (padding + message)

    def systemExit(self, errorCode, message):
        try:
            if errorCode == 0:
                self.myPrintMessage("Exit program.", paddingType=0)
            else:
                self.myPrintMessage(message, paddingType=0)
            sys.exit(errorCode)
        except Exception as e:
            self.myPrintMessage('- error: ' + str(e), paddingType=1)
            self.myPrintMessage(traceback.print_exc(), paddingType=0)
            sys.exit(1)

    def assertTests(self):
        print ('Not implemented. Look at FileAndPathHandler.assertTests() for inspiration')
        return True