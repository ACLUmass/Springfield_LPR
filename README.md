# Springfield Police Department's use of License Plate Readers (LPRs)
This repo corresponds to the ACLUM blog post on Springfield's use of LPRs. The code and data is managed by Rebecca Pattichis, the Technology for Liberty Fellow at the ACLU of Massachusetts.

## Directory

There's two main documents in this repo, both under the `src/` folder:
1. prepare_data.Rmd: This pre-processes the dataset, walking through our logic for deduplication.
2. flock_blog.Rmd: This markdown file generates the interactive figures in the blog post, as well as outlines the code we used for the data in our prose.

## Data
You can download the clean dataset by clicking [this link](https://data.aclum.org/wp-content/uploads/2026/11/flock_combined_24-26.csv.zip). The data is consolidated from data obtained from a public records request to Springfield PD. They consist of Flock audit logs from January 2024 to October 2026. 

The following columns are present in the data. Note that the descriptions below are ours, and are therefore are :
- `ID`: A presumably unique identifier for each search.
- `Name`: Name of the officer conducting the search.
- `Org.Name`: Police department running the search.
- `Total.Networks.Searched`: The amount of networks (e.g., police department datasets) that were searched through.
- `Time.Frame`: Time frame of data to search through.
- `License.Plate`: License plate that is being searched for. Usually empty or redacted.
- `Reason`: Reason listed by the officer for the search. Doesn't seem to be uniform / standardized nationwide.
- `Case`: Case number the search is associated to. Usually empty or redacted.
- `Filters`: Any additional written-in filters. Usually empty or redacted.
- `Search.Time`: The timestamp, in UTC time zone, down to the second, that the search was conducted.
- `Search.Type`: The options are 'search' or 'lookup', with an additional marker for whether it is a 'mobile' search. We are unclear what this represents.
- `Text.Prompt`: A natural language prompt that the officer supplied alongside the search.
- `Moderation`: Indicates whether a search was allowed or blocked by Flock's moderation system. This field seems to be non-empty when the search is accompanied by a natural language text prompt.
- `Total.Devices.Searched`: We believe this is how many LPRs were searched through (i.e., assuming it includes LPRs in the PD's data network).

The data we received necessitated several layers of deduplication. Firstly, the PD gave us files with overlapping dates and therefore multiple data. After basic deduplication matching across all columns, for example, we went from over 13 million data to ~11 million.

### Extra deduplication

Apart from the exact match deduplication, there's another layer of deduplication we took. Given that the data spans over almost 3 years worth of data, and that there is overlap in the data, there were a few things to consider:
- In 2024, there was no `ID` column marked for each data point.
- Among the duplicate files, there are different elements that are filled in versus redacted versus missing. For example, while one file listes the name of the police officer conducting the search, another file redacts it with '***' or leaves it completely blank.

Because of both of these points, we had to rely on a fuzzier approach to finding duplicates. There are two conditions that we checked for duplication:
1. `Name ` & `Search.Time` & `Time.Frame` & `Reason` & `Search.Type` (under the `dup1_check` column)
2. `Org.Name` & `Search.Time` & `Time.Frame` & `Reason` & `Search.Type`(under the `dup2_check` column)

These two are compiled through and OR operation, such that the `duplicate_likely` column represents the following duplication check: (`dup1_check`) | (`dup2_check`).

After this deduplication process, we ended up with 10,605,174 unique rows.
