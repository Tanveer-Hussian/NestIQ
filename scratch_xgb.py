import xgboost as xgb
import numpy as np
X = np.random.rand(10, 5)
y = np.random.rand(10)
model = xgb.XGBRegressor(n_estimators=2, max_depth=2)
model.fit(X, y)
trees = model.get_booster().get_dump(dump_format='json')
with open('test_trees.json', 'w') as f:
    f.write('[' + ','.join(trees) + ']')
