import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import os

# Load data
df = pd.read_csv('hostel_training_data.csv')

X = df[['rating', 'complaint_freq', 'resolution_rate', 'resolution_speed_hrs', 'booking_rate', 'price_ratio', 'completeness']].values
y = df['target_score'].values

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Build a Deep Neural Network model for Regression
model = tf.keras.Sequential([
    tf.keras.layers.Dense(32, activation='relu', input_shape=(7,)),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(1, activation='linear') # Output a single continuous value (score)
])

model.compile(optimizer='adam', loss='mse', metrics=['mae'])

# Train the model
print("Training ML Model...")
model.fit(X_train, y_train, epochs=30, batch_size=32, validation_split=0.2, verbose=1)

# Evaluate
loss, mae = model.evaluate(X_test, y_test, verbose=0)
print(f"Test MAE (Mean Absolute Error): {mae:.2f}")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model
with open('recommendation_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Saved recommendation_model.tflite successfully.")
