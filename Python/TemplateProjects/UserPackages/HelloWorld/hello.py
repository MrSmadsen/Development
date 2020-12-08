# Version and Github_upload date: 1.0 (08-12-2020)
# Author/Developer: Søren Madsen
# Github url: https://github.com/MrSmadsen/Development/tree/main/Python/TemplateProjects/
# Desciption: This is a python project to show how to add your own user packages to the python
# path variable and use it in a python script or python program.
# Test_Disclaimer: This script/program has been tested on: Microsoft Windows 10 64bit home (Danish).
#                  Feel free to use this script/software at your own risk.

class CoolHello:
    def __init__(self):
        self.name = "Name_CoolHello"

    def printHelloMessage(self, message=''):
        print('Hello From ' + self.name, flush=True)
        print('Message: ' + message, end="", flush=True)
