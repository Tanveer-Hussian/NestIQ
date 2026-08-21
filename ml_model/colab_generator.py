# Run this exact script in Google Colab (https://colab.research.google.com/)
# It will generate the `recommendation_model.tflite` file and download it to your computer.

import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from google.colab import files

# 1. Generate 5000 fake hostel records
NUM_SAMPLES = 5000

data = {
    'rating': np.random.uniform(1.0, 5.0, NUM_SAMPLES),
    'complaint_freq': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'resolution_rate': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'resolution_speed_hrs': np.random.uniform(0, 150, NUM_SAMPLES),
    'booking_rate': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'price_ratio': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'completeness': np.random.uniform(0.2, 1.0, NUM_SAMPLES),
}

df = pd.DataFrame(data)

# Calculate a realistic "ground truth" score based on our business logic to train the model
score_rating = (df['rating'] / 5.0) * 35.0
score_freq = (1.0 - df['complaint_freq']) * 10.0
score_res_rate = df['resolution_rate'] * 5.0
score_speed = np.where(df['resolution_speed_hrs'] <= 48, 10.0, 
              np.where(df['resolution_speed_hrs'] <= 96, 5.0, 2.0))
score_complaint = score_freq + score_res_rate + score_speed
score_booking = df['booking_rate'] * 20.0
score_price = df['price_ratio'] * 10.0
score_completeness = df['completeness'] * 10.0

noise = np.random.normal(0, 2.0, NUM_SAMPLES)
df['target_score'] = score_rating + score_complaint + score_booking + score_price + score_completeness + noise
df['target_score'] = df['target_score'].clip(0, 100)

# 2. Train the Model
X = df[['rating', 'complaint_freq', 'resolution_rate', 'resolution_speed_hrs', 'booking_rate', 'price_ratio', 'completeness']].values
y = df['target_score'].values

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = tf.keras.Sequential([
    tf.keras.layers.Dense(32, activation='relu', input_shape=(7,)),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(1, activation='linear')
])

model.compile(optimizer='adam', loss='mse', metrics=['mae'])
print("Training ML Model...")
model.fit(X_train, y_train, epochs=30, batch_size=32, validation_split=0.2, verbose=1)

# 3. Convert and Export to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('recommendation_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Downloading model...")
files.download('recommendation_model.tflite')
