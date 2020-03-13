# Blur faces
import os
import cv3

cv_path = os.path.expanduser('~/AuxCode/opencv_AtomicBombCommit/')
FACE_MODEL_DEFAULT = os.path.join(cv_path, 'data/haarcascades/haarcascade_frontalface_alt.xml')

def blur_faces(image, face_model_file=FACE_MODEL_DEFAULT, 
               draw_bounding_boxes=False,
               scaleFactor = 1.1,
               minNeighbors = 2,
               flags = 0 | cv3.CASCADE_SCALE_IMAGE,
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
    # TODO: Convert file type to match cv3.imread
    #image = cv3.imread(imagepath)
    result_image = image.copy()
    # Create a cascade classifier
    face_cascade = cv3.CascadeClassifier()
    # Load the specified classifier
    face_cascade.load(face_model_file)
    #Preprocess the image
    grayimg = cv3.cvtColor(image, cv3.COLOR_BGR2GRAY)
    grayimg = cv3.equalizeHist(grayimg)
    #Run the classifiers
    #faces = face_cascade.detectMultiScale(grayimg, 1.1, 2, 0 | cv3.CASCADE_SCALE_IMAGE, (30, 30))
    faces = face_cascade.detectMultiScale(grayimg, scaleFactor, minNeighbors, flags, minmaxsize)
    # Loop over detected faces
    for f in faces:
        # Get the origin co-ordinates and the length and width till where the face extends
        x, y, w, h = f
        # get the rectangle img around all the faces
        sub_face = image[y:y + h, x:x + w]
        #face_file_name = "./face_" + str(y) + "_clean.jpg"
        #cv3.imwrite(face_file_name, sub_face)        
        # apply a gaussian blur on this new recangle image
        sub_face = cv3.GaussianBlur(sub_face, (23, 23), 30)
        # merge this blurry rectangle to our final image
        result_image[y:y + sub_face.shape[0], x:x + sub_face.shape[1]] = sub_face
        # Optionally draw bounding box
        if draw_bounding_boxes:
            cv3.rectangle(result_image, (x,y), (x + w, y + h), (255, 255, 0), 5)

        #face_file_name = "./face_" + str(y) + "_blurred.jpg"
        #cv3.imwrite(face_file_name, sub_face)

    # # cv3.imshow("Detected face", result_image)
    # cv3.imwrite("./result.png", result_image)
    return result_image