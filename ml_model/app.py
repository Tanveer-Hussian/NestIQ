from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import tensorflow as tf
from tensorflow.keras.preprocessing.sequence import pad_sequences
import json
import os
import uvicorn

app = FastAPI()

# Load model and tokenizer
model = None
tokenizer_word_index = {}
vocab_size = 1000
max_length = 20

@app.on_event("startup")
def load_assets():
    global model, tokenizer_word_index
    if os.path.exists('fake_review_model.h5'):
        model = tf.keras.models.load_model('fake_review_model.h5')
    if os.path.exists('tokenizer.json'):
        with open('tokenizer.json', 'r') as f:
            tokenizer_word_index = json.load(f)

def text_to_sequence(text, word_index, max_len):
    # Simple manual tokenization matching Keras Tokenizer
    words = text.lower().split()
    seq = []
    for w in words:
        if w in word_index and word_index[w] < vocab_size:
            seq.append(word_index[w])
        else:
            seq.append(word_index.get("<OOV>", 1))
    
    # Pad sequence
    if len(seq) < max_len:
        seq = seq + [0] * (max_len - len(seq))
    else:
        seq = seq[:max_len]
    return [seq]

class ReviewRequest(BaseModel):
    comment: str
    rating: float = 0.0

@app.post("/predict_review")
async def predict_review(request: ReviewRequest):
    if not request.comment:
        raise HTTPException(status_code=400, detail="comment required")
        
    comment = request.comment
    
    if model is None:
        # Fallback heuristic if model failed to load
        is_suspicious = False
        if len(comment.strip()) < 10:
            is_suspicious = True
        return {'is_suspicious': is_suspicious, 'score': 1.0 if is_suspicious else 0.0}

    # Preprocess
    padded = text_to_sequence(comment, tokenizer_word_index, max_length)
    
    # Predict
    prediction = model.predict(padded)[0][0]
    is_fake = bool(prediction > 0.5)
    
    return {
        'is_suspicious': is_fake,
        'score': float(prediction)
    }

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    uvicorn.run("app:app", host='0.0.0.0', port=port)
