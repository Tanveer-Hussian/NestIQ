import firebase_admin
from firebase_admin import credentials, firestore, storage
import pandas as pd
import xgboost as xgb
import json
import os
import random

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Use Application Default Credentials when deployed to GCP/Cloud Functions
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'fyp-smart-hostel.appspot.com' # Needs to be updated with real bucket
        })
    except Exception:
        # Fallback if already initialized or testing
        try:
            firebase_admin.initialize_app()
        except ValueError:
            pass

def fetch_real_data(db):
    """
    Fetch hostels from Firestore to build a training dataset.
    Features: average_rating, complaint_resolution_rate, review_volume, num_bookings, proximity
    """
    print("Fetching data from Firestore...")
    hostels_ref = db.collection('hostels').stream()
    
    data = []
    
    for doc in hostels_ref:
        hostel = doc.to_dict()
        
        rating = float(hostel.get('averageRating', 0.0))
        review_volume = float(hostel.get('totalReviews', 0))
        num_bookings = float(hostel.get('totalBookings', 0))
        complaint_res_rate = float(hostel.get('complaintResolutionRate', 1.0))
        
        # Since distance (proximity) depends on the user's location at inference time,
        # we generate synthetic proximity values to teach the model the relationship
        # between distance and the final score during training.
        for _ in range(5):
            proximity = random.uniform(0.5, 20.0) # 0.5km to 20km
            
            # Ground truth target score formula logic
            score = (rating * 15) + (complaint_res_rate * 10) + (min(review_volume, 100) * 0.1) + (min(num_bookings, 100) * 0.2)
            
            # Distance penalty/bonus
            if proximity < 2.0:
                score += 15
            elif proximity < 5.0:
                score += 5
            else:
                score -= proximity * 0.5
                
            data.append({
                'average_rating': rating,
                'complaint_resolution_rate': complaint_res_rate,
                'review_volume': review_volume,
                'num_bookings': num_bookings,
                'proximity': proximity,
                'target_score': max(0.0, min(100.0, score)) # Clamp 0-100
            })
            
    return pd.DataFrame(data)

def generate_synthetic_data():
    """Fallback if Firestore has no data yet."""
    print("Generating synthetic data since Firestore is empty...")
    data = []
    for _ in range(1000):
        rating = random.uniform(1.0, 5.0)
        complaint_res_rate = random.uniform(0.0, 1.0)
        review_volume = random.uniform(0, 200)
        num_bookings = random.uniform(0, 300)
        proximity = random.uniform(0.5, 20.0)
        
        score = (rating * 15) + (complaint_res_rate * 10) + (min(review_volume, 100) * 0.1) + (min(num_bookings, 100) * 0.2)
        if proximity < 2.0:
            score += 15
        elif proximity < 5.0:
            score += 5
        else:
            score -= proximity * 0.5
            
        data.append({
            'average_rating': rating,
            'complaint_resolution_rate': complaint_res_rate,
            'review_volume': review_volume,
            'num_bookings': num_bookings,
            'proximity': proximity,
            'target_score': max(0.0, min(100.0, score))
        })
    return pd.DataFrame(data)

def train_and_export():
    initialize_firebase()
    
    # Try fetching real data
    try:
        db = firestore.client()
        df = fetch_real_data(db)
        if df.empty:
            df = generate_synthetic_data()
    except Exception as e:
        print(f"Could not fetch from Firestore (running locally?): {e}")
        df = generate_synthetic_data()
    
    print(f"Training XGBRegressor on {len(df)} records...")
    X = df[['average_rating', 'complaint_resolution_rate', 'review_volume', 'num_bookings', 'proximity']].values
    y = df['target_score'].values
    
    model = xgb.XGBRegressor(n_estimators=100, max_depth=3, learning_rate=0.1)
    model.fit(X, y)
    
    # Export XGBoost tree to JSON format
    trees = model.get_booster().get_dump(dump_format='json')
    json_model = "[" + ",".join(trees) + "]"
    
    local_path = 'xgboost_model.json'
    with open(local_path, 'w') as f:
        f.write(json_model)
        
    print(f"Model saved locally to {local_path}")
    
    # Upload to Firebase Storage so the Flutter app can download the updated weights
    try:
        bucket = storage.bucket()
        blob = bucket.blob('ml_models/xgboost_model.json')
        blob.upload_from_filename(local_path)
        print("Model pushed to Firebase Storage successfully!")
    except Exception as e:
        print(f"Skipped uploading to Firebase Storage: {e}")

if __name__ == '__main__':
    train_and_export()
