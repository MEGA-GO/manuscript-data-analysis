import itertools

SAMPLES, = glob_wildcards("go-per-sample/go_terms_{sample}.csv")


rule all:
    input:
        expand("similarity/{sample_comb}.csv",
               sample_comb=[f"{c[0]}-vs-{c[1]}" for c in itertools.combinations(SAMPLES, 2)])


rule bwa_map:
    input:
        "go-per-sample/go_terms_{sample_a}.csv",
        "go-per-sample/go_terms_{sample_b}.csv"
    output:
        "similarity/{sample_a}-vs-{sample_b}.csv"
    shell:
        "megago {input} > {output}"
