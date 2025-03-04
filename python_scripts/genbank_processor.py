from Bio import SeqIO
import re
import argparse

def contains_t2_or_higher(protein_id):
    return bool(re.search(r'T[2-9][0-9]*', protein_id))

def main(input_file, output_file):
    gb_file = SeqIO.parse(open(input_file, "r"), "genbank")
    modified_records = []  # Store modified records

    total_features = 0
    total_duplicates = 0
    total_locus_tags = 0

    for gb_record in gb_file:
        # print(f'============= RECORD =============')
        # print(f'Name -> {gb_record.name}')
        # print(f'\nAnnotations -> {gb_record.annotations}')
        # print(f'\nDescription -> {gb_record.description}')
        # print(f'\nID -> {gb_record.id}')
        # print(f'\nBDX refs -> {gb_record.dbxrefs}')
        #
        # print(f'============= FEATURES =============')
        duplicate_count = 0
        locus_tags = set()
        duplicate_indices = []  # Store indices of duplicate features

        for i, gb_feature in enumerate(gb_record.features):
            locus_tag = gb_feature.qualifiers.get('locus_tag')
            if not locus_tag:
                continue

            locus_tags.add(locus_tag[0])

            protein_id = gb_feature.qualifiers.get('protein_id')
            if not protein_id:
                continue

            if ((not locus_tag[0] in protein_id[0])  # Remove if the locus tag and protein ID don't match
                    or contains_t2_or_higher(protein_id[0])): # Remove if there are duplicates (T2 etc)
                duplicate_count += 1
                duplicate_indices.append(i)

                if not locus_tag[0] in protein_id[0]:
                    print(f'\n============= MISMATCH =============')
                    print(f'Protein ID -> {protein_id[0]} + Locus tag -> {locus_tag[0]}')

                if contains_t2_or_higher(protein_id[0]):
                    print(f'\n============= DUPLICATE =============')
                    print(f'Protein ID -> {protein_id[0]}')

        # Remove duplicates by index in reverse order
        for index in sorted(duplicate_indices, reverse=True):
            del gb_record.features[index]

        # print(f'\nFeature duplicate_count after removal -> {len(gb_record.features)}')
        # print(f'Locus tags -> {len(locus_tags)}')
        # print(f'Duplicate duplicate_count -> {duplicate_count}')

        total_features += len(gb_record.features)
        total_locus_tags += len(locus_tags)
        total_duplicates += duplicate_count

        # Append modified record to the list
        modified_records.append(gb_record)

    print(f'\n\nTOTAL Count -> {total_features}')
    print(f'TOTAL Locus tags -> {total_locus_tags}')
    print(f'TOTAL Duplicate or mismatches -> {total_duplicates}')

    # Write the modified records to a new GenBank file
    with open(output_file, "w") as output_handle:
        SeqIO.write(modified_records, output_handle, "genbank")

    print(f"Modified GenBank file saved as {output_file}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Process GenBank file to remove duplicate features.")
    parser.add_argument("--input", required=True, help="Input GenBank file")
    parser.add_argument("--output", required=True, help="Output GenBank file for modified data")
    args = parser.parse_args()

    main(args.input, args.output)
