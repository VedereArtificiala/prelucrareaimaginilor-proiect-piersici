import tensorflow as tf
import tensorflow_hub as hub
from tensorflow.keras import Sequential, layers
import os
import numpy as np
from io import BytesIO
import base64
from flask import Flask, request, jsonify


flowers_dir = "./flowers"
flower_labels = sorted(os.listdir(flowers_dir))
flower_labels


# img_height = 299
# img_width = 299
img_height = 224
img_width = 224

model = tf.keras.Sequential(
    [
        layers.experimental.preprocessing.Rescaling(
            1.0 / 255, input_shape=(img_height, img_width, 3)
        ),
        hub.KerasLayer(
            # "https://tfhub.dev/google/imagenet/inception_v3/feature_vector/4",
            "https://www.kaggle.com/models/tensorflow/resnet-50/frameworks/TensorFlow2/variations/classification/versions/1",
            trainable=False,
        ),
        # tf.keras.layers.Dense(64, activation="relu"),
        # tf.keras.layers.Dense(5, activation="softmax"),
        tf.keras.layers.Dense(512, activation="relu"),
        tf.keras.layers.Dense(100, activation="softmax"),
    ]
)


model.compile(
    optimizer="adam", loss="sparse_categorical_crossentropy", metrics="accuracy"
)

model.load_weights("./flowers2.h5")

app = Flask(__name__)


@app.route("/upload_image", methods=["POST"])
def upload_image():
    try:
        # Get the Base64-encoded image from the request
        data = request.get_json()
        base64_image = data.get("image", "")

        # Decode the Base64-encoded image
        image_data = base64.b64decode(base64_image)

        # Load the image using tf.keras.utils.load_img
        img = tf.keras.utils.load_img(
            BytesIO(image_data), target_size=(img_height, img_width)
        )  # Adjust target_size as needed

        img_array = tf.keras.utils.img_to_array(img)
        img_array = tf.expand_dims(img_array, 0)

        predictions = model.predict(img_array)
        score = tf.nn.softmax(predictions[0])

        score_percent = 100 * np.max(score)
        flower_name = flower_labels[np.argmax(score)]

        print("----- {} {:.2f} -----".format(flower_name, score_percent))

        if score_percent > 2.3:
            return flower_name
        else:
            return "Unknown"

    except Exception as e:
        print(e)

        return "error"


if __name__ == "__main__":
    app.run(debug=False, port=63333, host="0.0.0.0")
