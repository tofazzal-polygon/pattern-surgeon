from impl import OrderService


def test_create_uses_collaborator():
    svc = OrderService()
    new_id = svc.create("widget")
    assert new_id == "id-fixed"
    assert svc.created == [{"id": "id-fixed", "name": "widget"}]
