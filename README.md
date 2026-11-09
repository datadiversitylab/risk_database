# IUCNN risk database

## Groups

    01-amphibians
    02-reptiles
    03-chondrichthyans
    04-freshwater
    05-orchids
    06-birds
    07-mammals

## Structure

Project Structure

risk_database/  
├── input/  
│   ├── 01-amphibians/  
│   ├── 02-reptiles/  
│   ├── 03-chondrichthyans/  
│   ├── 04-freshwater/  
│   ├── 05-orchids/  
│   │   ├── training_occ.csv  
│   │   ├── training_labels.csv  
│   │   └── prediction_occ.csv  
│   ├── 06-birds/  
│   ├── 07-mammals/  
│   ├── official/  
│   └── human_footprint/  
├── output/  
│   └── 05-orchids/  
│       ├── model_01/  
│       │   └── nn_model_0.keras  
│       └── predictions.rds  
└── scripts/  
    ├── IUCNN_test.R  
    └──  README.md

    
