import time
import enum
from GenericFunctions.utility import CoolUtility

class EnumDateTimeFormat(enum.IntEnum):
    DATETIMEFORMAT_UNSUPPORTED = 1
    DATETIMEFORMAT_YYYY_MM_DD = 2
    DATETIMEFORMAT_YYYY_MM_DD__TIME_HH_MM_SS = 3
    DATETIMEFORMAT_YYYY_MM_DD__TIME_HH_MM = 4

class TimeDateHandler:

    moduleName = "TimeDateHandler Class"  # This is a class variable shared by ALL instances

    def __init__(self):
        self.name = "TimeDateHandler"
        self.utility = CoolUtility()

    def getCurrentTime(self):
        timeSinceEpoch = time.time()
        return timeSinceEpoch

    def isDateTimeStringEmptyOrZeroBased(self, dateTimeString):
        result = False

        if (((str(dateTimeString) == '0000:00:00 00:00:00')) or ((str(dateTimeString) == '0000:00:00')) or ((self.utility.stringIsEmpty(dateTimeString, False) == True))):
            result = True
        else:
            result = False

        return result

    # Verify dateTimeString by format: 'YYY:MM:DD HH:MM:SS' or 'YYY:MM:DD'
    # return true if string is valid.
    def checkDateTimeField_FormatDate_YYYY_MM_DD__TIME_HH_MM_SS(self, dateTimeString):
        result = False
        format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
        value = ''
        tokens = None
        subTokens = None

        #Check minimum length: YYYY:MM:DD HH:MM, 16 chars
        if (len(dateTimeString) >= 16):
            pass
        else:
            format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
            return format

        # YYYY:MM:DD HH:MM:SS or YYYY:MM:DD HH:MM
        tokens = dateTimeString.split(' ')  # Result: tokens[0]: Date, tokens[1]: time.

        # YYYY:MM:DD HH:MM:SS or YYYY:MM:DD HH:MM
        if ((len(tokens) == 2) == True):
            value = tokens[0]
            subTokens = value.split(':')  # Result: tokens[0]: Year, tokens[1]: Month, tokens[2]: day.

            if ((len(subTokens) == 3) == True):  # YYYY:MM:DD, length and tokens are digits
                if (((len(subTokens[0]) == 4) == True) and ((len(subTokens[1]) == 2) == True) and ((len(subTokens[2]) == 2) == True)):
                    if ((str(subTokens[0]).isdigit() is True) and (str(subTokens[1]).isdigit() is True) and (str(subTokens[2]).isdigit() is True)):
                        result = True
                    else:
                        result = False
                else:
                    result = False
            else:
                result = False

            subTokens = None
            value = ''

            if (result == True):  # HH:MM:SS or HH:MM
                value = tokens[1]
                subTokens = value.split(':')  # Result: tokens[0]: Year, tokens[1]: Month, tokens[2]: day.

                if ((len(subTokens) == 3) == True):  # HH:MM:SS
                    if (((len(subTokens[0]) == 2) == True) and ((len(subTokens[1]) == 2) == True) and ((len(subTokens[2]) == 2) == True)):
                        if ((str(subTokens[0]).isdigit() is True) and (str(subTokens[1]).isdigit() is True) and (str(subTokens[2]).isdigit() is True)):
                            result = True
                            format = EnumDateTimeFormat.DATETIMEFORMAT_YYYY_MM_DD__TIME_HH_MM_SS
                        else:
                            result = False
                            format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
                    else:
                        result = False
                        format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
                elif ((len(subTokens) == 2) == True):  # HH:MM
                    if (((len(subTokens[0]) == 2) == True) and ((len(subTokens[1]) == 2) == True)):
                        if ((str(subTokens[0]).isdigit() is True) and (str(subTokens[1]).isdigit() is True)):
                            result = True
                            format = EnumDateTimeFormat.DATETIMEFORMAT_YYYY_MM_DD__TIME_HH_MM
                        else:
                            result = False
                            format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
                    else:
                        result = False
                        format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
                else:
                    result = False
                    format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
            else:
                pass
        elif ((len(tokens) == 1) == True):  # YYYY:MM:DD
            value = tokens[0]
            subTokens = value.split(':')  # Result: tokens[0]: Year, tokens[1]: Month, tokens[2]: day.

            if ((len(subTokens) == 3) == True):  # YYYY:MM:DD
                if (((len(subTokens[0]) == 4) == True) and ((len(subTokens[1]) == 2) == True) and ((len(subTokens[2]) == 2) == True)):
                    if ((str(subTokens[0]).isdigit() is True) and (str(subTokens[1]).isdigit() is True) and (str(subTokens[2]).isdigit() is True)):
                        result = True
                        format = EnumDateTimeFormat.DATETIMEFORMAT_YYYY_MM_DD
                    else:
                        result = False
                        format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
                else:
                    result = False
                    format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED
            else:
                result = False
                format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED

            subTokens = None
            value = ''
        else:
            result = False
            format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED

        return format

    def isDateTimeFieldValid(self, dateTimeString):
        result = False

        if ((self.isExifDateTimeFieldValid(dateTimeString) is True) or (self.isFileStatResultDataTimeFieldValid(dateTimeString) is True)):
            result = True

        return result

    def isExifDateTimeFieldValid(self, dateTimeString):
        result = False
        stringIsZeroOrEmpty = False
        format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED

        stringIsZeroOrEmpty = self.isDateTimeStringEmptyOrZeroBased(dateTimeString)

        if (stringIsZeroOrEmpty is True):
            result = False
        else:
            format = self.checkDateTimeField_FormatDate_YYYY_MM_DD__TIME_HH_MM_SS(dateTimeString)

            if (format is EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED):
                result = False
            else:
                result = True

        return result

    def isFileStatResultDataTimeFieldValid(self, dateTimeString):
        result = False
        stringIsZeroOrEmpty = False
        format = EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED

        stringIsZeroOrEmpty = self.isDateTimeStringEmptyOrZeroBased(dateTimeString)

        if (stringIsZeroOrEmpty is True):
            result = False
        else:
            format = self.checkDateTimeField_FormatDate_YYYY_MM_DD__TIME_HH_MM_SS(dateTimeString)

            if (format is EnumDateTimeFormat.DATETIMEFORMAT_UNSUPPORTED):
                result = False
            else:
                result = True

        return result

class TimeDurationMeasurement:
    moduleName = "TimeDurationMeasurement"

    def __init__(self):
        self.name = "TimeDurationMeasurement"
        self.utility = CoolUtility()
        self.Mode = ""
        self.functionIdxDictionary = {}
        self.timingResults = [[]]

    # Setup a two dimensional fixed size array list structure to store start and end timestamps.
    # Add a total duration list entry ?
    def setupTimeMeasurementStartEndDelta(self, timedFunctions):
        heigth = 0  # FunctionList (Outer array scope).
        width = 3  # StartTime, EndTime, DeltaTime (Inner array scope).

        if timedFunctions is not []:
            for entries in timedFunctions:
                self.functionIdxDictionary[timedFunctions[heigth]] = heigth
                heigth += 1

            self.timingResults = [['' for x in range(width)] for y in range(heigth)]
            self.Mode = str("StartEndDelta")
            result = True
        else:
            result = False

        return result

    # [ [total, avg, max, min, measurement1,measurement2,measurement2,measurement2,measurementN] Outer function list]
    # Setup a two array list structure to store Continuous measurements.
    #def setupTimeMeasurementContinuousMeasurements(self, timedFunctions):
    #    result = False
    #    self.Mode = str("Continuous")
    #    return result

    def storeMeasurementStartEndDelta(self, functionName, timeStampStart=None, timeStampEnd=None):
        if (functionName):
            if (timeStampStart is not None):
                idx = self.functionIdxDictionary.get(functionName)
                self.timingResults[idx][0] = timeStampStart
                result = True

            if (timeStampEnd is not None):
                idx = self.functionIdxDictionary.get(functionName)
                self.timingResults[idx][1] = timeStampEnd
                result = True

            if ((timeStampStart is None) and (timeStampEnd is None)):
                result = False
        else:
            result = False

        return result

    #def storeContinuousMeasurement(self, timedFunctions):
    #    result = False
    #    return result

    # Calculate timing.
    def calculate(self):
        if self.Mode == str("Continuous"):
            pass
        elif self.Mode == str("StartEndDelta"):
                for entries in self.functionIdxDictionary:
                    idx = self.functionIdxDictionary.get(entries)
                    timeStampStart = self.timingResults[idx][0]
                    timeStampEnd = self.timingResults[idx][1]

                    if timeStampStart != '' and timeStampEnd != '':
                        self.timingResults[idx][2] = (timeStampEnd - timeStampStart)
        else:
            pass

    def displayDuration(self, functionName):
        #Remember to support both modes.
        if self.Mode == str("StartEndDelta"):
            if functionName:
                if functionName == str("summary"):  # Display all entries.
                    for entries in self.functionIdxDictionary:
                        idx = self.functionIdxDictionary.get(entries)
                        deltaTime = self.timingResults[idx][2]

                        if deltaTime:
                            elapsedMinutes = int((deltaTime) / 60)
                            elapsedSeconds = int(deltaTime) - (elapsedMinutes * 60)
                            self.utility.myPrintMessage('Measured time ' + entries + ': ' + str(elapsedMinutes) + 'm ' + str(elapsedSeconds) + 's\n',paddingType=1)
                        else:   # Skipped entries with no delta time stored.
                            pass
                else:  # Display specific entry.
                    idx = self.functionIdxDictionary.get(functionName)
                    if idx in range(len(self.functionIdxDictionary)):
                        deltaTime = self.timingResults[idx][2]
                        if deltaTime:
                            elapsedMinutes = int((deltaTime) / 60)
                            elapsedSeconds = int(deltaTime) - (elapsedMinutes * 60)
                            self.utility.myPrintMessage('Measured time ' + functionName + ': ' + str(elapsedMinutes) + 'm ' + str(elapsedSeconds) + 's\n',paddingType=1)
                    else:  # Skipped entries with no delta time stored.
                        pass
        elif self.Mode == str("Continuous"):
            pass
        else:
            pass

    def displayDurationSummary(self):
        self.displayDuration("summary")

