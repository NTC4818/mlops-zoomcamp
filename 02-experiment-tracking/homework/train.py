import os
import pickle
import click
import mlflow
import logging

from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import root_mean_squared_error

# Set the tracking URI to a local SQLite database file
mlflow.set_tracking_uri("sqlite:///mlruns.db")

# Set the default artifact URI to a local folder named 'artifacts'
# mlflow.set_artifact_uri("./artifacts")
# -----------------------------------------------------------------
logging.basicConfig(level=logging.DEBUG)


def load_pickle(filename: str):
    with open(filename, "rb") as f_in:
        return pickle.load(f_in)


@click.command()
@click.option(
    "--data_path",
    default="./output",
    help="Location where the processed NYC taxi trip data was saved"
)
def run_train(data_path: str):

    # Enable autologging for scikit-learn
    mlflow.sklearn.autolog()
    
    #start mlflow run
    with mlflow.start_run():

        X_train, y_train = load_pickle(os.path.join(data_path, "train.pkl"))
        X_val, y_val = load_pickle(os.path.join(data_path, "val.pkl"))

        rf = RandomForestRegressor(max_depth=10, random_state=0)
        rf.fit(X_train, y_train)
        y_pred = rf.predict(X_val)

        rmse = root_mean_squared_error(y_val, y_pred)
        # You can also manually log additional metrics or parameters if needed
        mlflow.log_metric("rmse", rmse)


if __name__ == '__main__':
    run_train()