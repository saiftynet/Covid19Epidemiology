# Covid19Epidemiology

John Hopkins has collected data for COVID-19 cases to be used for general public consumption and analysis. This code aims to allow the data to be used in Perl applications to observe data points, display trends graphically and perform statistical anaylysis.

The importer script is developed using experience from EZPWC, creates a local clone of the John Hopkins repo, converts the data into simple hashes and stores them locally. This hash is then used by other scripts to generate tables and charts or transform the data into other formats (e.g. for embedding or use in other tools).
