import unittest

from unpack.unpack_model import _character_bone_paths, _character_skeleton_paths


class SharedAnimationPathTests(unittest.TestCase):
    def test_outfit_skeleton_paths_include_twist_bones_but_not_summons(self) -> None:
        paths = _character_skeleton_paths("10301")
        self.assertIn(
            "Root/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 LThighTwist", paths)
        self.assertIn(
            "Root/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1/Bip001 Neck/"
            "Bip001 L Clavicle/Bip001 L UpperArm/Bip001 L ForeTwist", paths)
        self.assertNotIn("Root/Body_WeiYi/Bone_001", paths)

    def test_skinned_bones_exclude_weapon_only_clips(self) -> None:
        paths = _character_bone_paths("11201")

        self.assertIn("Root/Bip001/Bip001 Pelvis", paths)
        self.assertNotIn("weapon", paths)
