import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import json
import os

def generate_data():
    # Synthetic data for real and fake reviews
    # Fake reviews: often very short, repetitive, extreme ratings, generic
    fake_reviews = [
        ("Good", 5), ("Nice", 5), ("Very good", 5), ("Worst", 1), ("Bad", 1),
        ("Terrible", 1), ("Awesome", 5), ("Hated it", 1), ("Love it", 5),
        ("greaaaaat!!!", 5), ("very bad don't go", 1), ("best hostel ever!!!", 5),
        ("awful", 1), ("okay", 3), ("so bad", 1), ("perfect", 5),
        ("A", 1), ("no", 1), ("yes", 5)
    ] * 20 # duplicate to increase dataset size
    
    # Real reviews: longer, more descriptive
    real_reviews = [
        ("The rooms are quite clean but the food is average.", 3),
        ("I had a great stay, the staff was very helpful and the location is good.", 4),
        ("The internet was very slow, making it hard to study. However, the room was nice.", 2),
        ("Excellent facilities, everything was well maintained and the warden is friendly.", 5),
        ("Terrible experience. The bathroom was always dirty and there was no hot water.", 1),
        ("Good value for money, but the laundry machines are usually busy.", 4),
        ("The environment is quite peaceful and suitable for students.", 4),
        ("I didn't like the food menu, it's very repetitive every week.", 2),
        ("Security is great, I felt very safe during my stay here.", 5),
        ("The location is too far from the university campus.", 2),
        ("Overall a decent place, but could improve cleanliness in the common areas.", 3),
    ] * 40
    
    data = []
    for text, rating in fake_reviews:
        data.append({'text': text, 'rating': rating, 'is_fake': 1})
    for text, rating in real_reviews:
        data.append({'text': text, 'rating': rating, 'is_fake': 0})
        
    df = pd.DataFrame(data)
    # Shuffle
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    return df

def train_model():
    print("Generating synthetic data...")
    df = generate_data()
    
    # Text preprocessing and tokenization
    texts = df['text'].astype(str).values
    labels = df['is_fake'].values
    
    # Simple Tokenizer
    vocab_size = 1000
    max_length = 20
    
    tokenizer = Tokenizer(num_words=vocab_size, oov_token="<OOV>")
    tokenizer.fit_on_texts(texts)
    
    sequences = tokenizer.texts_to_sequences(texts)
    padded_sequences = pad_sequences(sequences, maxlen=max_length, padding='post')
    
    # Save the tokenizer dictionary
    word_index = tokenizer.word_index
    with open('tokenizer.json', 'w') as f:
        json.dump(word_index, f)
        
    print("Building model...")
    # FastText-like architecture (Embedding + GlobalAveragePooling)
    model = tf.keras.Sequential([
        tf.keras.layers.Embedding(vocab_size, 16, input_length=max_length),
        tf.keras.layers.GlobalAveragePooling1D(),
        tf.keras.layers.Dense(16, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid')
    ])
    
    model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])
    
    print("Training model...")
    model.fit(padded_sequences, labels, epochs=10, validation_split=0.2, verbose=1)
    
    print("Saving model to fake_review_model.h5...")
    model.save('fake_review_model.h5')
    print("Training complete.")

if __name__ == '__main__':
    train_model()
