# (a wooden bridge, a dog, 90)
# (an submarine, a whale, 270) 
# (an airplane, a banana, 90)
# (a turtle, a tank, 0/180) (TBD)
# (an elephant, a chair, 90)

text1="a turtle"
text2="a tank"

# replace ' ' with '_'
concat_text1=$(echo $text1 | sed 's/ /_/g')
concat_text2=$(echo $text2 | sed 's/ /_/g')

# w_ids=(0 1 1 1 1 1 1)
# w_rotateds=(1 0 1 2 3 4 5)
w_ids=(0 1 1)
w_rotateds=(1 0 1)
rotation_angle=0 # rotation angle of text 2 with respect to text 1

for ((j = 0; j < ${#w_ids[@]}; j++)); do
    w_id=${w_ids[j]}
    w_rotated=${w_rotateds[j]}

    exp_dir=/project/yi-ray/GaussianCube/exp/${concat_text1}_${concat_text2}/${w_id}_${w_rotated}
    mkdir -p $exp_dir

    cd /project/yi-ray/GaussianCube
    python inference_illusion.py \
        --model_name objaverse_v1.1 \
        --exp_name /tmp/objaverse_test_ddpm \
        --config configs/objaverse_text_cond.yml \
        --text "$text1" \
        --text2 "$text2" \
        --guidance_scale 3.5 \
        --rescale_timesteps 200 \
        --num_samples 1 \
        --render_video \
        --w_id $w_id \
        --w_rotated $w_rotated \
        --rotation_angle $rotation_angle \

    cp /tmp/objaverse_test_ddpm/videos/rank_00_render_000000.mp4 ${exp_dir}/
    mv ${exp_dir}/rank_00_render_000000.mp4 ${exp_dir}/output.mp4

    cd /project/yi-ray/evaluation
    python vid2imgs.py \
        --video_path ${exp_dir}/output.mp4 \
        --output_folder ${exp_dir}/output_imgs

    cd /project/yi-ray/evaluation/improved-aesthetic-predictor
    python evaluate_folder.py \
        --folder_path ${exp_dir}/output_imgs \
        --output_folder ${exp_dir}

    cd ${exp_dir}
    mkdir -p ${exp_dir}/text1
    mkdir -p ${exp_dir}/text2
    # for every images in $exp_dir/output_imgs, 
    # create a txt file in the ./text1 with the filename the same as the image, 
    # and store the text1 in the txt file
    for img in $(ls ${exp_dir}/output_imgs); do
        img=${img%.*}
        echo $text1 > ${exp_dir}/text1/$img.txt
        echo $text2 > ${exp_dir}/text2/$img.txt
    done

    python -m clip_score ${exp_dir}/output_imgs ${exp_dir}/text1 > ${exp_dir}/text1_score.txt
    python -m clip_score ${exp_dir}/output_imgs ${exp_dir}/text2 > ${exp_dir}/text2_score.txt
done


# baseline
baseline_text="A 3D model of a hybrid between ${text1} and ${text2}."

w_id=1
w_rotated=0
rotation_angle=0

exp_dir=/project/yi-ray/GaussianCube/exp/${concat_text1}_${concat_text2}/baseline
mkdir -p $exp_dir

cd /project/yi-ray/GaussianCube
python inference_illusion.py \
    --model_name objaverse_v1.1 \
    --exp_name /tmp/objaverse_test_ddpm \
    --config configs/objaverse_text_cond.yml \
    --text "$baseline_text" \
    --text2 "" \
    --guidance_scale 3.5 \
    --rescale_timesteps 200 \
    --num_samples 1 \
    --render_video \
    --w_id $w_id \
    --w_rotated $w_rotated \
    --rotation_angle $rotation_angle \

cp /tmp/objaverse_test_ddpm/videos/rank_00_render_000000.mp4 ${exp_dir}/
mv ${exp_dir}/rank_00_render_000000.mp4 ${exp_dir}/output.mp4

cd /project/yi-ray/evaluation
python vid2imgs.py \
    --video_path ${exp_dir}/output.mp4 \
    --output_folder ${exp_dir}/output_imgs

cd /project/yi-ray/evaluation/improved-aesthetic-predictor
python evaluate_folder.py \
    --folder_path ${exp_dir}/output_imgs \
    --output_folder ${exp_dir}

cd ${exp_dir}
mkdir -p ${exp_dir}/text1
mkdir -p ${exp_dir}/text2
# for every images in $exp_dir/output_imgs, 
# create a txt file in the ./text1 with the filename the same as the image, 
# and store the text1 in the txt file
for img in $(ls ${exp_dir}/output_imgs); do
    img=${img%.*}
    echo $text1 > ${exp_dir}/text1/$img.txt
    echo $text2 > ${exp_dir}/text2/$img.txt
done

python -m clip_score ${exp_dir}/output_imgs ${exp_dir}/text1 > ${exp_dir}/text1_score.txt
python -m clip_score ${exp_dir}/output_imgs ${exp_dir}/text2 > ${exp_dir}/text2_score.txt