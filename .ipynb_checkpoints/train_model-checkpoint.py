# Setup

import sklearn as sk
import numpy as np
import pandas as pd
import os
import pickle

# Import Data
dataFile = os.path.join(
    os.environ["PWD"],
    "data",
    "smallPrepared.csv"
)

df = pd.read_csv(dataFile, header=0, index_col=0)

# Train model

columns = list(df.columns)
columns.remove("churn_Y")
y = df["churn_Y"].values
X = df[columns].values

from sklearn.ensemble import GradientBoostingClassifier
gb1 = GradientBoostingClassifier(loss = "exponential", max_depth=3)
gb1 = gb1.fit(X, y)
gb1prb = gb1.predict_proba(X)

# Save model as Python Pickle file

modelSaveFile = os.path.join(
    os.environ["PWD"],
    "results",
    "gb1.pkl"
)

pickle.dump(gb1, open(modelSaveFile, "wb"))