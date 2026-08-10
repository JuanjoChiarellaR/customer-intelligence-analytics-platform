from pathlib import Path
import pandas as pd

RAW_DIR = Path("data/raw")
OUTPUT_DIR = Path("data/processed")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

files = [
    "Telco_customer_churn_demographics.xlsx",
    "Telco_customer_churn_location.xlsx",
    "Telco_customer_churn_population.xlsx",
    "Telco_customer_churn_services.xlsx",
    "Telco_customer_churn_status.xlsx",
]

for filename in files:
    input_path = RAW_DIR / filename
    output_path = OUTPUT_DIR / f"{input_path.stem}.csv"

    df = pd.read_excel(input_path)
    df.to_csv(output_path, index=False)

    print(f"{filename} -> {output_path} | {len(df):,} rows")