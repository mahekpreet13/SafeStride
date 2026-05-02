import geopandas as gpd
from shapely.geometry import Point

RADIUS_TO_CHECK = 50
SHAPE_FILE_PATH = "data/regensburg_dangerous_streets.shp"
GEOJSON_FILE_PATH = "data/regensburg_tiles.json"

dangerous_roads = None
tiles_geo = None

def load_map():
    global dangerous_roads, tiles_geo
    dangerous_roads = gpd.read_file(SHAPE_FILE_PATH).to_crs(epsg=3857)
    tiles_geo = gpd.read_file(GEOJSON_FILE_PATH).to_crs(epsg=3857)

    tiles_geo = tiles_geo[tiles_geo["danger_score"] >= 3]


def get_dangerous_roads(lat: float, lon: float):
    point = gpd.GeoSeries(Point(lon, lat), crs="EPSG:4326")
    point = point.to_crs(epsg=3857)

    # circle = point.buffer(RADIUS_TO_CHECK)  # 100 meter radius
    # intersecting_roads = dangerous_roads[dangerous_roads.intersects(
    #     circle.iloc[0])]

    intersecting = tiles_geo[tiles_geo.intersects(point.iloc[0])]

    return intersecting.geometry.tolist()
