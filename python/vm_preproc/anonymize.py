# Blur faces
import os
try:
    import cv2 as cv
except:
    print("cv2 import failed; attempting to import cv3!")
    import cv3 as cv

#cv_path = os.path.expanduser('~/AuxCode/opencv_AtomicBombCommit/')
cv_path = os.path.abspath(cv.__path__[0])
#FACE_MODEL_DEFAULT = os.path.join(cv_path, 'data/haarcascades/haarcascade_frontalface_alt.xml')
FACE_MODEL_DEFAULT = os.path.join(cv_path, 'data/haarcascade_frontalface_alt.xml')
if not os.path.exists(FACE_MODEL_DEFAULT):
    raise ValueError('Missing face model in open cv')

def blur_faces(image, face_model_file=FACE_MODEL_DEFAULT, 
               draw_bounding_boxes=False,
               scaleFactor = 1.1,
               minNeighbors = 2,
               flags = 0 | cv.CASCADE_SCALE_IMAGE,
               minmaxsize = (15, 200)
               ):
    """Blur faces detected in a given image array
    
    im : array-like
        image array to blur (X x Y x Color)
    face_model_file :str 
        Specifies the trained cascade classifier

    Notes
    -----
    TO DO : make sure scales are appropriate / work
    
    """
    # TODO: Convert file type to match cv.imread
    #image = cv.imread(imagepath)
    result_image = image.copy()
    # Create a cascade classifier
    face_cascade = cv.CascadeClassifier()
    # Load the specified classifier
    face_cascade.load(face_model_file)
    #Preprocess the image
    grayimg = cv.cvtColor(image, cv.COLOR_BGR2GRAY)
    grayimg = cv.equalizeHist(grayimg)
    #Run the classifiers
    #faces = face_cascade.detectMultiScale(grayimg, 1.1, 2, 0 | cv.CASCADE_SCALE_IMAGE, (30, 30))
    faces = face_cascade.detectMultiScale(grayimg, scaleFactor, minNeighbors, flags, minmaxsize)
    # Loop over detected faces
    for f in faces:
        # Get the origin co-ordinates and the length and width till where the face extends
        x, y, w, h = f
        # get the rectangle img around all the faces
        sub_face = image[y:y + h, x:x + w]
        #face_file_name = "./face_" + str(y) + "_clean.jpg"
        #cv.imwrite(face_file_name, sub_face)        
        # apply a gaussian blur on this new recangle image
        sub_face = cv.GaussianBlur(sub_face, (23, 23), 30)
        # merge this blurry rectangle to our final image
        result_image[y:y + sub_face.shape[0], x:x + sub_face.shape[1]] = sub_face
        # Optionally draw bounding box
        if draw_bounding_boxes:
            cv.rectangle(result_image, (x,y), (x + w, y + h), (255, 255, 0), 5)

        #face_file_name = "./face_" + str(y) + "_blurred.jpg"
        #cv.imwrite(face_file_name, sub_face)

    # # cv.imshow("Detected face", result_image)
    # cv.imwrite("./result.png", result_image)
    return result_image