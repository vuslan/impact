# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.


def print_hi(name):
    # Use a breakpoint in the code line below to debug your script.
    print(f'Hi, {name}')  # Press Ctrl+F8 to toggle the breakpoint.

def test_05(): #Project001.lif_Series006_z0_ch02.tif
    import numpy as np
    import cv2
    img = cv2.imread("Project001.lif_Series006_z0_ch02.tif")
    cv2.namedWindow("Image", cv2.WINDOW_NORMAL)
    cv2.imshow("Image", img)
    cv2.waitKey(0)

def test_04(): #M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg
    import numpy as np
    import cv2
    img = cv2.imread("M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg")
    cv2.namedWindow("Image", cv2.WINDOW_NORMAL)
    cv2.imshow("Image", img)
    cv2.waitKey(0)

def test_03(): #Project001_Series005_z0.tif
    import numpy as np
    import cv2
    img = cv2.imread("Project001_Series005_z0.tif")
    cv2.namedWindow("Image", cv2.WINDOW_NORMAL)
    cv2.imshow("Image", img)
    cv2.waitKey(0)

def test_02():
    import numpy as np
    import cv2
    img = cv2.imread("opencv-logo.png", 1)
    img
    
def test_01():
    import numpy as np
    import cv2
    img = cv2.imread("opencv-logo.png")
    cv2.namedWindow("Image", cv2.WINDOW_NORMAL)
    cv2.imshow("Image", img)
    cv2.waitKey(0)
    cv2.imwrite("output.jpg", img)    

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    print_hi('PyCharm')
    test_05()

# See PyCharm help at https://www.jetbrains.com/help/pycharm/


