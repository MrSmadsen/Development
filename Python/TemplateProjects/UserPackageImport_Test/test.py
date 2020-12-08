# Version and Github_upload date: 1.0 (08-12-2020)
# Author/Developer: Søren Madsen
# Github url: https://github.com/MrSmadsen/Development/tree/main/Python/TemplateProjects/
# Desciption: This is a python project to show how to add your own user packages to the python
# path variable and use it in a python script or python program.
# Test_Disclaimer: This script/program has been tested on: Microsoft Windows 10 64bit home (Danish).
#                  Feel free to use this script/software at your own risk.

import os
import sys
sys.path.append(os.path.normpath(os.path.abspath("..\\UserPackages")))
from HelloWorld.hello import CoolHello

print ('\n')
print (sys.path)
print ('\n')

if __name__ == '__main__':
    print ('UserPackage Import test!')
    print ('Path to HelloWorld package should be: ..\\UserPackage\\HelloWorld')
    print ('Then by adding ..\\UserPackages to sys.path the import function can se HelloWorld and its content:')
    print ('from HelloWorld.hello import CoolHello')
    print ('HelloWorld is a package.')
    print ('hello is a python .py module - (a python file hello.py)')
    print ('CoolHello is a python class in the python .py module named hello\n')
    
    try:
        myHelloHandler = CoolHello()
        myHelloHandler.printHelloMessage('Cool message. Hello Python User\n')
    except Exception as e:
        print(str(traceback.print_exc()))
