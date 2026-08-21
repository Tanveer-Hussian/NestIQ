import pandas as pd
import numpy as np
import random

# Generate 5000 fake hostel records
NUM_SAMPLES = 5000

data = {
    'rating': np.random.uniform(1.0, 5.0, NUM_SAMPLES),
    'complaint_freq': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'resolution_rate': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'resolution_speed_hrs': np.random.uniform(0, 150, NUM_SAMPLES),
    'booking_rate': np.random.uniform(0.0, 1.0, NUM_SAMPLES),
    'price_ratio': np.random.uniform(0.0, 1.0, NUM_SAMPLES), # 1.0 is cheapest relative to city
    'completeness': np.random.uniform(0.2, 1.0, NUM_SAMPLES),
}

df = pd.DataFrame(data)

# Calculate a realistic "ground truth" score based on our business logic to train the model
# Rating: up to 35 pts
score_rating = (df['rating'] / 5.0) * 35.0

# Complaint: up to 25 pts
# frequency: 1 - freq (10 pts)
score_freq = (1.0 - df['complaint_freq']) * 10.0
# rate: rate (5 pts)
score_res_rate = df['resolution_rate'] * 5.0
# speed: under 48=10, under 96=5, else 2
score_speed = np.where(df['resolution_speed_hrs'] <= 48, 10.0, 
              np.where(df['resolution_speed_hrs'] <= 96, 5.0, 2.0))
score_complaint = score_freq + score_res_rate + score_speed

# Booking: up to 20 pts
score_booking = df['booking_rate'] * 20.0

# Price: up to 10 pts
score_price = df['price_ratio'] * 10.0

# Completeness: up to 10 pts
score_completeness = df['completeness'] * 10.0

# Add some random noise so the neural network doesn't just memorize a linear equation
noise = np.random.normal(0, 2.0, NUM_SAMPLES)
df['target_score'] = score_rating + score_complaint + score_booking + score_price + score_completeness + noise
df['target_score'] = df['target_score'].clip(0, 100)

df.to_csv('hostel_training_data.csv', index=False)
print("Generated hostel_training_data.csv with", NUM_SAMPLES, "samples.")
