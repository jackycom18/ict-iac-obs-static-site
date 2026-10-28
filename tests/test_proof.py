"""验证 OBS 静态网站完成证明。"""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ProofTest(unittest.TestCase):
    """检查桶、对象和网站托管证明。"""

    def test_bucket_and_objects_exist(self):
        """功能：验证 OBS 证明；输入：无；输出：无。"""
        state = json.loads((ROOT / "proof/terraform.tfstate").read_text(encoding="utf-8"))
        types = {item["type"] for item in state["resources"]}
        self.assertIn("huaweicloud_obs_bucket", types)
        self.assertIn("huaweicloud_obs_bucket_object", types)
        bucket = next(
            item for item in state["resources"] if item["type"] == "huaweicloud_obs_bucket"
        )
        attrs = bucket["instances"][0]["attributes"]
        self.assertEqual("index.html", attrs["website"][0]["index_document"])
        self.assertEqual("error.html", attrs["website"][0]["error_document"])


if __name__ == "__main__":
    unittest.main()
