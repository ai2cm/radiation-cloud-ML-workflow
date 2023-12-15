.PHONY: update_submodule
update_submodule:
	git submodule sync --recursive
	git submodule update --recursive --init

.PHONY: create_environment
create_environment:
	make -C fv3net update_submodules && make -C fv3net create_environment

workflow_dag.png:
	cat workflow_dag.txt | dot -Tpng > workflow_dag.png

.PHONY: surface_reference_zarr
surface_reference_zarr:
	cd scripts && python ./surface_reference_zarr.py

.PHONY: fine_restarts_to_zarr
fine_restarts_to_zarr:
	cd workflows/fine-restarts-to-zarr && kubectl apply -f pod.yaml

.PHONY: nudge_to_fine_baseline_run
nudge_to_fine_baseline_run: deploy
	cd workflows/prognostic-run && ./run.sh nudge-to-fine-baseline 39

.PHONY: extend_prognostic_run
extend_prognostic_run: deploy
	cd workflows/prognostic-run && ./extend.sh $(URL) $(SEGMENTS)

.PHONY: training_data_zarr
training_data_zarr:
	cd scripts && python ./training_data_zarr.py training_data_zarr_config.yaml

.PHONY: prescribed_cloud_cc_decorr_run
prescribed_cloud_cc_decorr_run: deploy
	cd workflows/prognostic-run && ./run.sh prescribed-cloud-cc-decorr 39

.PHONY: prescribed_cloud_cc_max_random_run
prescribed_cloud_cc_max_random_run: deploy
	cd workflows/prognostic-run && ./run.sh prescribed-cloud-cc-max-random 39

.PHONY: prescribed_cloud_cc_random_run
prescribed_cloud_cc_random_run: deploy
	cd workflows/prognostic-run && ./run.sh prescribed-cloud-cc-random 39

.PHONY: prescribed_cloud_decorr_run
prescribed_cloud_decorr_run: deploy
	cd workflows/prognostic-run && ./run.sh prescribed-cloud-decorr 39

.PHONY: prescribed_cloud_max_random_run
prescribed_cloud_max_random_run: deploy
	cd workflows/prognostic-run && ./run.sh prescribed-cloud-max-random 39

.PHONY: prescribed_cloud_random_run
prescribed_cloud_random_run: deploy
	cd workflows/prognostic-run && ./run.sh prescribed-cloud-random 39

.PHONY: train_cloud_ml_dense_seed
train_cloud_ml_dense_seed: deploy
	cd workflows/training && ./run_random_seed.sh dense 4

.PHONY: train_cloud_ml_dense_nocoarsephys_seed
train_cloud_ml_dense_nocoarsephys_seed: deploy
	cd workflows/training && ./run_random_seed.sh dense-nocoarsephys 4

.PHONY: upload_squashed_models
upload_squashed_models:
	cd scripts/upload-squashed-models && ./upload.sh 4 $(URL)

.PHONY: upload_squashed_models_nocoarsephys
upload_squashed_models_nocoarsephys:
	cd scripts/upload-squashed-models && ./upload.sh \
	4 gs://vcm-ml-experiments/cloud-ml/2023-12-06/train-cloud-ml-dense-nocoarsephys \
	squash_thresholds_nocoarsephys.yaml \
	squashed_output_model_nocoarsephys.yaml

.PHONY: prescribed_cloud_dense_seed_squash_threshold
prescribed_cloud_dense_seed_squash_threshold: deploy
	cd workflows/prognostic-run && ./run_seed_squash_threshold.sh prescribed-cloud-dense 4 39

.PHONY: prescribed_cloud_dense_nocoarsephys_seed_squash_threshold
prescribed_cloud_dense_nocoarsephys_seed_squash_threshold: deploy
	cd workflows/prognostic-run && ./run_seed_squash_threshold.sh \
	prescribed-cloud-dense-ncp 4 39 squash_thresholds_nocoarsephys.yaml

.PHONY: offline_cloud_predictions_zarr
offline_cloud_predictions_zarr:
	cd scripts && python ./offline_predictions_zarr.py offline_predictions_config.yaml

.PHONY: offline_cloud_predictions_squashed_zarr
offline_cloud_predictions_squashed_zarr:
	cd scripts && python ./offline_predictions_zarr.py offline_predictions_squashed_config.yaml

.PHONY: offline_cloud_predictions_nocoarsephys_zarr
offline_cloud_predictions_nocoarsephys_zarr:
	cd scripts && python ./offline_predictions_zarr.py offline_predictions_nocoarsephys_config.yaml

.PHONY: offline_cloud_predictions_nocoarsephys_squashed_zarr
offline_cloud_predictions_nocoarsephys_squashed_zarr:
	cd scripts && python ./offline_predictions_zarr.py offline_predictions_nocoarsephys_squashed_config.yaml

.PHONY: deploy
deploy: workflows/kustomize
	cd workflows && ./kustomize build . | kubectl apply -f -

workflows/kustomize:
	cd workflows && ./install_kustomize.sh 3.10.0