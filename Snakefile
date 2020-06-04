import itertools
import pandas as pd

SAMPLES, = glob_wildcards("go-per-sample/go_terms_{sample}.csv")


rule all:
    input:
        expand("similarity/{sample_comb}.csv",
               sample_comb=[f"{c[0]}-vs-{c[1]}" for c in itertools.combinations(SAMPLES, 2)])
    output:
        molecular_function="similarity_mf.csv",
        biological_process="similarity_bp.csv",
        cellular_component="similarity_cc.csv"
    run:
        namespaces = ["molecular_function", "biological_process", "cellular_component"]
        df_dict = {namespace: pd.DataFrame(index=SAMPLES, columns=SAMPLES) for namespace in namespaces}
        for f_in in input:
            filename_wo_ext = f_in.split("/")[-1].split(".")[0]
            s1, s2 = filename_wo_ext.split("-vs-")
            df_s = pd.read_csv(f_in, index_col=0)
            for namespace, df_agg in df_dict.items():
                sim = df_s.loc[namespace, "SIMILARITY"]
                df_agg.loc[s1, s2] = sim
                df_agg.loc[s2, s1] = sim
        for namespace, df_agg in df_dict.items():
            f_out = output[namespace]
            df_agg.to_csv(f_out)



rule calc_pairwise_sample_similarity:
    input:
        "go-per-sample/go_terms_{sample_a}.csv",
        "go-per-sample/go_terms_{sample_b}.csv"
    output:
        "similarity/{sample_a}-vs-{sample_b}.csv"
    shell:
        "megago {input} > {output}"
