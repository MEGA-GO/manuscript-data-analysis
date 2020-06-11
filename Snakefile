import itertools
import matplotlib
matplotlib.use('Agg')
import pandas as pd
import seaborn as sns

SAMPLES, = glob_wildcards("go-per-sample/go_terms_{sample}.csv")


rule all:
    input:
        molecular_function="figures/similarity_mf.svg",
        biological_process="figures/similarity_bp.svg",
        cellular_component="figures/similarity_cc.svg"

rule visualization:
    input:
        molecular_function="aggregated_sim/similarity_mf.csv",
        biological_process="aggregated_sim/similarity_bp.csv",
        cellular_component="aggregated_sim/similarity_cc.csv"
    output:
        molecular_function="figures/similarity_mf.svg",
        biological_process="figures/similarity_bp.svg",
        cellular_component="figures/similarity_cc.svg"
    run:
        df_dict = {namespace: pd.read_csv(f, index_col=0) for namespace, f in input.items()}
        index_sorted = sorted(df_dict["molecular_function"].index, key=lambda s: s[-2]+s[:3])
        width = 6
        for i, (namespace, df) in enumerate(df_dict.items()):
            cluster_grid = sns.clustermap(df, xticklabels=True, yticklabels=True)
            cluster_grid.savefig(output[namespace])

rule aggregate_similaries:
    input:
        expand("similarity/{sample_comb}.csv",
               sample_comb=[f"{sorted(c)[0]}-vs-{sorted(c)[1]}" for c in itertools.combinations_with_replacement(SAMPLES, 2)])
    output:
        molecular_function="aggregated_sim/similarity_mf.csv",
        biological_process="aggregated_sim/similarity_bp.csv",
        cellular_component="aggregated_sim/similarity_cc.csv"
    run:
        namespaces = ["molecular_function", "biological_process", "cellular_component"]
        df_dict = {namespace: pd.DataFrame(index=sorted(SAMPLES), columns=sorted(SAMPLES)) for namespace in namespaces}
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
    log: "similarity/{sample_a}-vs-{sample_b}.log"
    shell:
        "megago --log {log} {input} > {output}"
