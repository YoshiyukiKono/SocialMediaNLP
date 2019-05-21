library(dplyr)
library(sparklyr)

config <- spark_config()

config$sparklyr.driver.memory <- "16G"
config$sparklyr.executor.memory <- "16G"
config$spark.yarn.executor.memoryOverhead <- "8g"

#### Configuration for sparklyr
config[["spark.r.command"]] <- "./r_env.zip/r_env/bin/Rscript"
config[["spark.yarn.dist.archives"]] <- "r_env.zip"
config$sparklyr.apply.env.R_HOME <- "./r_env.zip/r_env/lib/R"
config$sparklyr.apply.env.RHOME <- "./r_env.zip/r_env"
config$sparklyr.apply.env.R_SHARE_DIR <- "./r_env.zip/r_env/lib/R/share"
config$sparklyr.apply.env.R_INCLUDE_DIR <- "./r_env.zip/r_env/lib/R/include"
config$sparklyr.apply.env.LD_LIBRARY_PATH <- "/opt/cloudera/parcels/Anaconda/lib"
config$sparklyr.apply.env.PYTHONPATH <- "./r_env.zip/r_env/lib/python2.7/site-packages/"
# Spacyr checkes if Python exits using "which/where" command, so PATH is needed even when using the full path.
config$sparklyr.apply.env.PATH <- "/opt/cloudera/parcels/Anaconda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/centos/.local/bin:/home/centos/bin"

#### Connect spark
sc <- spark_connect(master = "yarn-client", config = config)

tbl_cache(sc, 'sentiment_data')
sentiment_tbl <- tbl(sc, 'sentiment_data')

#### Extract named entities with `spark_apply()`
entities <- sentiment_tbl %>%
  select(body) %>%
  spark_apply(
    function(e) 
    {
      lapply(e, function(k) {
          spacyr::spacy_initialize()
          ##spacyr::spacy_initialize(python_executable="/opt/cloudera/parcels/Anaconda/bin/python")
          parsedtxt <- spacyr::spacy_parse(as.character(k), lemma = FALSE)
          spacyr::entity_extract(parsedtxt)
        }
      )
    },
    names = c("doc_id", "sentence_id", "entity", "entity_type"),
    packages = FALSE)

#### Show entities
entities %>% head(10) %>% collect()

#### Group entities
grouped_entities <- entities %>% 
  group_by(entity_type) %>% 
  count() %>% 
  arrange(desc(n)) %>%
  collect()
  
grouped_entities

#### Plot the graph

library(ggplot2)

p <- entities %>%
  collect() %>% 
  ggplot(aes(x=factor(entity_type)))
p <- p + scale_y_log10()
p + geom_bar()
