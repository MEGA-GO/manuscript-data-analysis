rule bwa_map:
    input:
        "go-per-sample/go_terms_{sample_a}.csv",
        "go-per-sample/go_terms_{sample_b}.csv"
    output:
        "similarity/{sample_a}-vs-{sample_b}.csv"
    shell:
        "megago {input} > {output}"