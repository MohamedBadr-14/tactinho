from flask import Flask, request, jsonify
import numpy as np
from typing import List, Dict, Any
from scipy.spatial.distance import cdist
from sklearn.preprocessing import MinMaxScaler
from sklearn.neighbors import NearestNeighbors
import json

scenes_arr = [
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [31.621706008911133, 58.6456184387207],
            },
            1: {
                "bbox": (1008, 796, 1056, 932),
                "team": 1,
                "position": (1032, 932),
                "position_transformed": [40.26863479614258, 46.887027740478516],
                # "has_ball": True,
            },
            3: {
                "bbox": (1040, 573, 1091, 693),
                "team": 1,
                "position": (1065, 693),
                "position_transformed": [40.5976676940918, 37.92753219604492],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [1070, 821, 1086, 837],
                "position": (1078, 829),
                "position_transformed": [40.82175064086914, 43.4152717590332],
            }
        },
        "goalkeeper": {
            2: {
                "bbox": (2128, 735, 2192, 867),
                "conf": None,
                "position": (2160, 867),
                "position_transformed": [54.96403884887695, 45.9318962097168],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2434.5, 751.83], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [30.92011833190918, 59.85486602783203],
            },
            1: {
                "bbox": (530, 915, 629, 1036),
                "team": 1,
                "position": (579, 1036),
                "position_transformed": [33.526309967041016, 51.44015121459961],
                # "has_ball": True,
            },
            2: {
                "bbox": (1147, 788, 1237, 921),
                "team": 0,
                "position": (1192, 921),
                "position_transformed": [40.126380920410156, 48.61543655395508],
            },
            4: {
                "bbox": (987, 561, 1049, 667),
                "team": 1,
                "position": (1018, 667),
                "position_transformed": [37.659603118896484, 38.218502044677734],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "bbox": [570.0, 1008.0, 597.0, 1037.0],
                "conf": 0.11,
                "position": (583, 1022),
                "position_transformed": [33.507484436035156, 51.055931091308594],
            }
        },
        "goalkeeper": {
            3: {
                "bbox": (2354, 693, 2412, 811),
                "conf": None,
                "position": (2383, 811),
                "position_transformed": [56.11859893798828, 45.926490783691406],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2540.5, 715.09], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [31.012386322021484, 60.09418869018555],
            },
            1: {
                "bbox": (422, 964, 485, 1074),
                "team": 1,
                "position": (453, 1074),
                "position_transformed": [32.21120071411133, 53.09784698486328],
                # "has_ball": True,
            },
            2: {
                "bbox": (597, 932, 709, 1068),
                "team": 0,
                "position": (653, 1068),
                "position_transformed": [34.11555099487305, 53.242427825927734],
            },
            4: {
                "bbox": (968, 543, 1045, 646),
                "team": 1,
                "position": (1006, 646),
                "position_transformed": [36.758758544921875, 38.33705139160156],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [442.0, 1080.0, 462.0, 1099.0],
                "position": (452, 1089),
                "position_transformed": [32.278934478759766, 53.46998596191406],
            }
        },
        "goalkeeper": {
            3: {
                "bbox": (2402, 665, 2470, 793),
                "conf": None,
                "position": (2436, 793),
                "position_transformed": [56.03960418701172, 47.44509506225586],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2539, 668.7], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [31.117626190185547, 60.91371154785156],
            },
            1: {
                "bbox": (398, 1019, 459, 1145),
                "team": 0,
                "position": (428, 1145),
                "position_transformed": [32.66943359375, 55.3180046081543],
            },
            2: {
                "bbox": (494, 1006, 538, 1142),
                "team": 1,
                "position": (516, 1142),
                "position_transformed": [33.486427307128906, 55.38705825805664],
                # "has_ball": True,
            },
            4: {
                "bbox": (638, 525, 691, 637),
                "team": 1,
                "position": (664, 637),
                "position_transformed": [32.6859130859375, 37.98685073852539],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [544.0, 1133.0, 565.0, 1154.0],
                "position": (554, 1143),
                "position_transformed": [33.85004806518555, 55.4716911315918],
            }
        },
        "goalkeeper": {
            3: {
                "bbox": (2285, 665, 2361, 784),
                "conf": None,
                "position": (2323, 784),
                "position_transformed": [55.57772445678711, 47.48074722290039],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2469.8, 657.79], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [30.5494441986084, 60.171844482421875],
            },
            1: {
                "bbox": (164, 1032, 280, 1195),
                "team": 0,
                "position": (222, 1195),
                "position_transformed": [30.124143600463867, 55.86209487915039],
                # "has_ball": True,
            },
            3: {
                "bbox": (552, 551, 597, 677),
                "team": 1,
                "position": (574, 677),
                "position_transformed": [29.599624633789062, 39.45939254760742],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [254.0, 1098.0, 276.0, 1117.0],
                "position": (265, 1107),
                "position_transformed": [29.909637451171875, 53.985755920410156],
            }
        },
        "goalkeeper": {
            2: {
                "bbox": (2192, 704, 2252, 827),
                "conf": None,
                "position": (2222, 827),
                "position_transformed": [51.30815505981445, 49.07210922241211],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2601.4, 649.65], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [30.308977127075195, 59.9102897644043],
            },
            1: {
                "bbox": (195, 972, 261, 1105),
                "team": 1,
                "position": (228, 1105),
                "position_transformed": [29.257631301879883, 53.52935028076172],
                "has_ball": True,
            },
            2: {
                "bbox": (324, 963, 396, 1124),
                "team": 0,
                "position": (360, 1124),
                "position_transformed": [30.63617706298828, 54.14975357055664],
            },
            4: {
                "bbox": (557, 583, 627, 701),
                "team": 1,
                "position": (592, 701),
                "position_transformed": [29.75140380859375, 40.02762985229492],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [265.0, 1068.0, 285.0, 1088.0],
                "position": (275, 1078),
                "position_transformed": [29.500211715698242, 52.93209457397461],
            }
        },
        "goalkeeper": {
            3: {
                "bbox": (2199, 700, 2249, 827),
                "conf": None,
                "position": (2224, 827),
                "position_transformed": [51.16606140136719, 48.27521896362305],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2647.6, 665.53], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [30.308977127075195, 59.9102897644043],
                "has_ball": True,
            },
            1: {
                "bbox": (195, 972, 261, 1105),
                "team": 1,
                "position": (228, 1105),
                "position_transformed": [35.257631301879883, 59.52935028076172],
            },
            2: {
                "bbox": (324, 963, 396, 1124),
                "team": 0,
                "position": (360, 1124),
                "position_transformed": [30.63617706298828, 54.14975357055664],
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [265.0, 1068.0, 285.0, 1088.0],
                "position": (275, 1078),
                "position_transformed": [30.500211715698242, 59.93209457397461],
            }
        },
        "goalkeeper": {
            3: {
                "bbox": (2199, 700, 2249, 827),
                "conf": None,
                "position": (2224, 827),
                "position_transformed": [51.16606140136719, 48.27521896362305],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2647.6, 665.53], dtype=np.float32),
            }
        },
    },
    {
        "players": {
            0: {
                "bbox": (55, 1369, 120, 1452),
                "team": 0,
                "position": (87, 1452),
                "position_transformed": [33.308977127075195, 62.9102897644043],
            },
            1: {
                "bbox": (195, 972, 261, 1105),
                "team": 1,
                "position": (228, 1105),
                "position_transformed": [35.257631301879883, 55.52935028076172],
            },
            2: {
                "bbox": (324, 963, 396, 1124),
                "team": 0,
                "position": (360, 1124),
                "position_transformed": [32.63617706298828, 30.14975357055664],
                "has_ball": True,
            },
        },
        "referees": {},
        "ball": {
            1: {
                "conf": 0.11,
                "bbox": [265.0, 1068.0, 285.0, 1088.0],
                "position": (275, 1078),
                "position_transformed": [32.500211715698242, 54.93209457397461],
            }
        },
        "goalkeeper": {
            3: {
                "bbox": (2199, 700, 2249, 827),
                "conf": None,
                "position": (2224, 827),
                "position_transformed": [51.16606140136719, 48.27521896362305],
            }
        },
        "goalpost": {
            1: {
                "position_transformed": (60, 42),
                "position": np.array([2647.6, 665.53], dtype=np.float32),
            }
        },
    },
]


def load_sequences_from_json(json_path):
    """
    Load sequences from a JSON file.
    The JSON should be a list of sequences, where each sequence is a list of scenes.
    """
    with open(json_path, "r") as f:
        data = json.load(f)
    return data

app = Flask(__name__)

# Your existing code (slightly modified for the API)
formation_features = [
    # Team shape features
    "team1_width",
    "team1_height",
    "team1_avg_spread",
    "team1_max_spread",
    "team1_min_pair_dist",
    "team1_avg_pair_dist",
    "team1_min_ball_dist",
    "team1_avg_ball_dist",
    "team2_width",
    "team2_height",
    "team2_avg_spread",
    "team2_max_spread",
    # Global features
    "ball_x",
    "ball_y",
]

def convert_numpy(obj):
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, dict):
        return {k: convert_numpy(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_numpy(item) for item in obj]
    return obj

class SceneMatcher:
    def __init__(self, goal_sequences):
        self.scenes, self.features = self.process_sequences(goal_sequences)
        self.scaler = MinMaxScaler()
        
    def extract_features(self, scene):
        """Extract only formation-relevant features (invariant to player ordering)."""
        features = {}
        players = scene["players"]
        team1 = [p for p in players.values() if p["team"] == 0]
        team2 = [p for p in players.values() if p["team"] == 1]

        # Team sizes (critical for filtering)
        features["team1_size"] = len(team1)
        features["team2_size"] = len(team2)

        # Ball position
        ball_pos = np.array([0.5, 0.5])  # Default field center
        if scene["ball"]:
            ball = next(iter(scene["ball"].values()))
            ball_pos = np.array(ball["position_transformed"])
            features["ball_x"] = ball_pos[0]
            features["ball_y"] = ball_pos[1]

        features["team1_has_ball"] = False
        for player in team1:
            if player.get("has_ball", False):
                features["team1_has_ball"] = True
                break

        # Process each team's formation
        for team_num, team in [(1, team1), (2, team2)]:
            prefix = f"team{team_num}_"
            if not team:
                continue

            positions = np.array([p["position_transformed"] for p in team])
            centroid = np.mean(positions, axis=0)

            # 1. Formation shape descriptors
            if len(positions) > 1:
                # Bounding box dimensions
                width = np.max(positions[:, 0]) - np.min(positions[:, 0])
                height = np.max(positions[:, 1]) - np.min(positions[:, 1])
                features[f"{prefix}width"] = width
                features[f"{prefix}height"] = height
                print("midoo", features)

                # Spread metrics
                dist_to_centroid = np.linalg.norm(positions - centroid, axis=1)
                features[f"{prefix}avg_spread"] = np.mean(dist_to_centroid)
                features[f"{prefix}max_spread"] = np.max(dist_to_centroid)

            # 2. Ball-relative positioning
            ball_dists = np.linalg.norm(positions - ball_pos, axis=1)
            features[f"{prefix}min_ball_dist"] = (
                np.min(ball_dists) if len(ball_dists) > 0 else 0
            )
            features[f"{prefix}avg_ball_dist"] = (
                np.mean(ball_dists) if len(ball_dists) > 0 else 0
            )

        return features
    
    def filter_scenes(self, query_feats, max_abs_dist=6):
        """Filter scenes in 2 stages:
        1. Exact team size match.
        2. Absolute position proximity (ball + centroids).
        """
        candidates = []

        # Stage 1: Team size matching
        for idx, scene_feats in self.features.items():
            print('hasball,scene_feats["team1_has_ball"]', scene_feats["team1_has_ball"])
            if (
                scene_feats["team1_size"] == query_feats["team1_size"]
                and scene_feats["team2_size"] == query_feats["team2_size"]
                and scene_feats["team1_has_ball"] == True
            ):
                candidates.append(idx)

        print("Candidates after team size match:", candidates)
        if not candidates:
            return []  # No matches with same team sizes
        # Stage 2: Absolute position filtering
        filtered = []
        query_ball = np.array([query_feats["ball_x"], query_feats["ball_y"]])

        for idx in candidates:
            scene_feats = self.features[idx]
            scene_ball = np.array([scene_feats["ball_x"], scene_feats["ball_y"]])
            ball_dist = np.linalg.norm(query_ball - scene_ball)
            print("Ball dist:", ball_dist)

            if ball_dist <= max_abs_dist:
                # and (
                #     not team_dists or all(d <= max_abs_dist for d in team_dists)
                # )

                filtered.append(idx)

        return filtered
    
    def match_formations(self, query_feats, candidate_indices):
        """Match formations using only the essential formation features."""
        if not candidate_indices:
            return None

        # Define our focused feature set

        # Build query vector
        query_vector = [query_feats.get(f, 0) for f in formation_features]
        print(query_feats)
        print("Query vector:", query_vector)

        # Build candidate matrix
        candidate_vectors = []
        valid_indices = []

        for idx in candidate_indices:
            scene_feats = self.features[idx]
            candidate_vec = [scene_feats.get(f, 0) for f in formation_features]
            candidate_vectors.append(candidate_vec)
            valid_indices.append(idx)

        if not valid_indices:
            return None

        # Normalize features
        all_features = np.array([query_vector] + candidate_vectors)
        means = np.mean(all_features, axis=0)
        stds = np.std(all_features, axis=0)
        stds[stds == 0] = 1  # Avoid division by zero
        print("Means:", means)
        print("Stds:", stds)
        print(all_features)

        norm_query = (query_vector - means) / stds
        norm_candidates = (np.array(candidate_vectors) - means) / stds

        # Find nearest neighbor
        nbrs = NearestNeighbors(n_neighbors=1, metric="euclidean").fit(norm_candidates)
        _, matches = nbrs.kneighbors([norm_query])

        return valid_indices[matches[0][0]]
    
    def process_sequences(self, goal_sequences):
        """Flatten all scenes into one array, each with id and next_id."""
        all_scenes = []
        features_obj = {}
        scene_id = 0

        for sequence in goal_sequences:
            for idx, scene in enumerate(sequence):
                features = self.extract_features(scene)

                # Determine next_id
                if idx < len(sequence) - 1:
                    next_id = scene_id + 1
                else:
                    next_id = None

                features_obj[scene_id] = features
                all_scenes.append(
                    {
                        "id": scene_id,
                        "original_scene": scene,
                        "features": features,
                        "next_id": next_id,
                    }
                )
                scene_id += 1

        return all_scenes, features_obj
    
    def get_sequence_from_match(self, initial_scene_id):
        """Follow next_id pointers to get a sequence"""
        sequence = []
        current_id = initial_scene_id
        
        while current_id is not None:
            scene = self.scenes[current_id]
            sequence.append(scene["original_scene"])
            current_id = scene.get("next_id", None)
        
        return sequence

# Initialize with your training data

matcher = SceneMatcher([scenes_arr[:7]])  # Pass your actual training sequences

@app.route('/api/predict_sequence', methods=['POST'])
def predict_sequence():
    """
    Endpoint that takes a scene and returns predicted sequence
    Example request body: {"scene": {players: {...}, ball: {...}}}
    """
    try:
        data = request.get_json()
        input_scene = data.get('scene')
        
        if not input_scene:
            return jsonify({"error": "No scene provided"}), 400
        
        # 1. Extract features from input scene
        query_feats = matcher.extract_features(input_scene)
        
        # 2. Filter candidate scenes
        candidates = matcher.filter_scenes(query_feats)
        
        # 3. Find best match
        matched_id = matcher.match_formations(query_feats, candidates)
        print("Matched ID:", matched_id)
        if matched_id is None:
            return jsonify({"error": "No matching scene found"}), 404
        
        # 4. Get the sequence
        sequence = matcher.get_sequence_from_match(matched_id)
        print("sequence:", sequence)
        
        serializable_sequence = convert_numpy(sequence)

        
        return jsonify({
            "status": "success",
            "matched_scene_id": matched_id,
            "sequence": serializable_sequence
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)